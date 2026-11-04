// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "business/profiles.h"
#include "context/import_result.h"
#include "context/dependencies.h"
#include "business/tunnel.h"
#include "observables/session.h"
#include <cassert>
#include <fstream>
#include <chrono>
#include <iostream>
#include <future>

using namespace Passepartout;
namespace {
Profile Example(std::string id = "test-id", std::string name = "Example") {
    Profile p{};
    p.id = std::move(id);
    p.name = std::move(name);
    Partout::Models::TaggedModuleCustom custom{};
    custom.value.innerType.value = Partout::Models::ModuleType::Provider;
    custom.value.json = {{"id", "provider-id"}};
    p.modules.push_back(custom);
    p.activeModulesIds.push_back("provider-id");
    return p;
}
template<typename Action>
void Rejects(Action action) {
    bool rejected = false;
    try {
        action();
    } catch (...) {
        rejected = true;
    }
    assert(rejected);
}
class ControlledTunnel final : public TunnelStrategy {
public:
    FakeTunnelStrategy fake;
    bool failConnect = false;
    bool delayedConnect = false;
    bool failFetch = false;
    bool delayedDisconnect = false;
    bool failDisconnect = false;
    bool failRemove = false;
    bool failSave = false;
    std::map<std::string, std::string> observationErrors;
    std::vector<std::string> events;
    std::vector<Models::AppTunnelInfo> Fetch() override {
        if (failFetch) throw std::runtime_error("VPN state unavailable");
        auto result = fake.Fetch();
        result.erase(std::remove_if(result.begin(), result.end(), [&](const auto &info) {
            return observationErrors.find(info.id) != observationErrors.end();
        }), result.end());
        return result;
    }
    std::map<std::string, std::string> ObservationErrors() const override {
        return observationErrors;
    }
    void Save(const Profile &p) override {
        events.push_back("save:" + p.id);
        if (failSave) throw std::runtime_error("Registration rejected");
        fake.Save(p);
    }
    void Connect(const std::string &id) override {
        events.push_back("connect:" + id);
        if (failConnect) throw std::runtime_error("Connection rejected");
        if (delayedConnect) fake.SetStatus(id, Status::connecting);
        else fake.Connect(id);
    }
    void Disconnect(const std::string &id) override {
        events.push_back("disconnect:" + id);
        if (failDisconnect) throw std::runtime_error("Disconnect rejected");
        const auto states = fake.Fetch();
        const bool exists = std::any_of(states.begin(), states.end(), [&](const auto &state) { return state.id == id; });
        if (delayedDisconnect && exists) fake.SetStatus(id, Status::disconnecting);
        else fake.Disconnect(id);
    }
    void Remove(const std::string &id) override {
        if (failRemove) throw std::runtime_error("Removal rejected");
        fake.Remove(id);
    }
};
struct Gate {
    std::promise<void> entered;
    std::promise<void> release;
};
class BlockingTunnel final : public TunnelStrategy {
public:
    explicit BlockingTunnel(std::shared_ptr<Gate> gate) : gate_(std::move(gate)) {}
    std::vector<Models::AppTunnelInfo> Fetch() override {
        return fake_.Fetch();
    }
    void Save(const Profile &p) override {
        fake_.Save(p);
    }
    void Connect(const std::string &id) override {
        gate_->entered.set_value();
        gate_->release.get_future().wait();
        fake_.Connect(id);
    }
    void Disconnect(const std::string &id) override {
        fake_.Disconnect(id);
    }
    void Remove(const std::string &id) override {
        fake_.Remove(id);
    }
private:
    std::shared_ptr<Gate> gate_;
    FakeTunnelStrategy fake_;
};
void Wait(AppSession &session) {
    assert(session.WaitIdle(std::chrono::seconds(5)));
}
}
int main() {
    {
        auto strategy = std::make_unique<ControlledTunnel>();
        auto *control = strategy.get();
        control->fake.Save(Example("broken"));
        control->observationErrors.emplace("broken", "Invalid handle");
        TunnelManager manager(std::move(strategy));
        manager.Save(Example("healthy"));
        manager.Connect(Example("healthy"));
        assert(!manager.PendingProfile());
        assert((control->events == std::vector<std::string>{"save:healthy", "connect:healthy"}));
        assert(manager.Fetch().at(0).status.value == Status::connected);
        assert(manager.ObservationErrors().count("broken") == 1);
        Rejects([&] { manager.Connect(Example("broken")); });
        assert(control->events.size() == 2);
    }
    auto constants = LoadAppConstants();
    assert(constants.containers.local == "Local");
    assert(ProfileDirectory("root", constants, defaultCrossConstants, false) == std::filesystem::path("root/local"));
    assert(ProfileDirectory("root", constants, defaultCrossConstants, true) == std::filesystem::path("root/demo-local"));
    constants.containers.local = "Testing";
    auto frontendConstants = defaultCrossConstants;
    frontendConstants.storage.demoPrefix = "preview-";
    assert(ProfileDirectory("root", constants, frontendConstants, true) == std::filesystem::path("root/preview-testing"));
    constants.containers.local = "../outside";
    Rejects([&] { ProfileDirectory("root", constants, frontendConstants, false); });
    const auto imported = Example();
    const auto success = nlohmann::json{{"payload", imported.ToJson()}};
    assert(DecodeImportResult(success.dump().c_str()) == imported);
    auto explicitSuccess = success;
    explicitSuccess["code"] = nullptr;
    assert(DecodeImportResult(explicitSuccess.dump().c_str()) == imported);
    auto failure = success;
    failure["code"] = "parsing";
    Rejects([&] { DecodeImportResult(failure.dump().c_str()); });
    Rejects([] { DecodeImportResult(nullptr); });
    Rejects([] { DecodeImportResult("not JSON"); });
    Rejects([] { DecodeImportResult("{}"); });
    Rejects([&] { DecodeImportResult(imported.ToJson().dump().c_str()); });
    const auto root = std::filesystem::temp_directory_path() /
        ("passepartout-test-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    std::filesystem::create_directories(root);
    try {
        const auto storageRoot = root / "layout";
        FileProfileRepository storage(storageRoot);
        assert(std::filesystem::is_directory(storageRoot / "tmp"));
        assert(nlohmann::json::parse(ReadConfiguration(storageRoot / "index.json")).at("version") == 1);
        auto earlier = Example("earlier", "ALPHA");
        earlier.userInfo = {{"lastUpdate", 1}, {"fingerprint", "first"}};
        auto later = Example("later", "alpha");
        later.userInfo = {{"lastUpdate", "2"}, {"fingerprint", "second"}};
        storage.Save(Example("zulu", "Zulu"));
        storage.Save(earlier);
        storage.Save(later);
        assert(std::filesystem::exists(storageRoot / "objects" / "later.json"));
        assert(std::filesystem::is_empty(storageRoot / "tmp"));
        assert(storage.Fetch().at(0).id == "later");
        auto index = nlohmann::json::parse(ReadConfiguration(storageRoot / "index.json"));
        assert(index.at("profiles").at(0).at("fingerprint") == "second");
        assert(index.at("profiles").at(0).at("lastUpdate") == "2");
        // A valid index defines fetch order, as on Android.
        std::reverse(index["profiles"].begin(), index["profiles"].end());
        std::ofstream(storageRoot / "index.json") << index.dump();
        assert(storage.Fetch().at(0).id == "zulu");
        // Interrupted index writes and missing indexes recover from objects.
        std::ofstream(storageRoot / "index.json") << "broken index";
        assert(storage.Fetch().at(0).id == "later");
        std::filesystem::remove(storageRoot / "index.json");
        assert(storage.Fetch().size() == 3);
        std::ofstream(storageRoot / "objects" / "unindexed.json") << Example("unindexed", "Beta").ToJson().dump();
        assert(storage.Fetch().size() == 4);
        // Missing indexed objects must not be silently treated as deletion.
        std::filesystem::remove(storageRoot / "objects" / "unindexed.json");
        Rejects([&] { storage.Fetch(); });
        storage.Remove("unindexed");
        assert(storage.Fetch().size() == 3);
        storage.Remove("later");
        assert(FileProfileRepository(storageRoot).Fetch().size() == 2);
        Rejects([&] { storage.Save(Example("CON")); });
        Rejects([&] { storage.Save(Example("../escape")); });
        FileProfileRepository repository(root / "profiles");
        auto p = Example();
        repository.Save(p);
        assert(repository.Fetch().at(0).name == "Example");
        p.name = "Updated";
        repository.Save(p);
        assert(repository.Fetch().size() == 1);
        assert(repository.Fetch().at(0).name == "Updated");
        Rejects([&] {
            repository.Save(Example("../escape"));
        });
        Rejects([&] {
            repository.Remove("../escape");
        });
        // Corruption must be reported and preserved, not treated as an empty store.
        const auto damaged = root / "profiles/objects/broken.json";
        std::ofstream(damaged) << "secret invalid configuration";
        Rejects([&] {
            repository.Fetch();
        });
        assert(std::filesystem::exists(damaged));
        std::filesystem::remove(damaged);

        const auto config = root / std::filesystem::u8path("名前 with spaces.conf");
        std::ofstream(config) << "test configuration";
        auto importer = [](const std::string &text, const std::string &name) {
            assert(text == "test configuration" || text == "another configuration");
            return Example(text == "test configuration" ? "imported" : "batch-id", name);
        };
        ProfileManager manager(std::make_unique<FileProfileRepository>(root / "profiles"), importer);
        Rejects([&] {
            manager.Import(config);
        });
        manager.Load();
        manager.Import(config);
        assert(manager.Find("imported").name == "名前 with spaces");
        Rejects([&] {
            manager.Import(config);
        });
        assert(manager.Profiles().size() == 2);

        auto controlled = std::make_unique<ControlledTunnel>();
        auto *strategy = controlled.get();
        TunnelManager tunnel(std::move(controlled));
        tunnel.Save(p);
        tunnel.Connect(p);
        assert(tunnel.Fetch().at(0).status.value == Status::connected);
        tunnel.Save(Example("second"));
        tunnel.Connect(Example("second"));
        assert(strategy->fake.Fetch().at(0).status.value == Status::disconnected);
        assert(strategy->fake.Fetch().at(1).status.value == Status::connected);
        assert((strategy->events == std::vector<std::string>{"save:" + p.id, "connect:" + p.id,
            "save:second", "disconnect:" + p.id, "connect:second"}));
        tunnel.Connect(p);
        tunnel.Remove("second");
        strategy->delayedDisconnect = true;
        Rejects([&] {
            tunnel.Remove(p.id);
        });
        assert(tunnel.Fetch().size() == 1);
        strategy->fake.SetStatus(p.id, Status::disconnected);
        tunnel.Remove(p.id);
        assert(tunnel.Fetch().empty());

        // Handover waits for observed deactivation, and a new accepted target replaces the old one.
        auto handoverBackend = std::make_unique<ControlledTunnel>();
        auto *handoverStrategy = handoverBackend.get();
        handoverStrategy->fake.Save(p);
        for (const auto *id : {"latest", "next", "failed", "cancelled", "connection-failure"})
            handoverStrategy->fake.Save(Example(id));
        handoverStrategy->fake.Connect(p.id);
        handoverStrategy->delayedDisconnect = true;
        TunnelManager handover(std::move(handoverBackend));
        handover.Connect(Example("next"));
        assert(handover.PendingProfile() == "next");
        handover.Advance();
        assert(handoverStrategy->events == std::vector<std::string>{"disconnect:" + p.id});
        handover.Connect(Example("latest"));
        handoverStrategy->fake.SetStatus(p.id, Status::disconnected);
        handover.Advance();
        assert(!handover.PendingProfile());
        assert((handoverStrategy->events == std::vector<std::string>{"disconnect:" + p.id, "connect:latest"}));
        handoverStrategy->failDisconnect = true;
        Rejects([&] { handover.Connect(Example("failed")); });
        assert(!handover.PendingProfile());
        assert(handoverStrategy->fake.Fetch().at(1).status.value == Status::connected);
        handoverStrategy->failDisconnect = false;
        handover.Connect(Example("cancelled"));
        handover.Disconnect("cancelled");
        assert(!handover.PendingProfile());
        handoverStrategy->fake.SetStatus("latest", Status::disconnected);
        handoverStrategy->fake.SetStatus("cancelled", Status::disconnected);
        handover.Advance();
        assert(handoverStrategy->fake.Fetch().size() == 6);
        handoverStrategy->failConnect = true;
        Rejects([&] { handover.Connect(Example("connection-failure")); });
        assert(!handover.PendingProfile());
        for (const auto &state : handover.Fetch()) assert(state.status.value == Status::disconnected);

        auto activationBackend = std::make_unique<ControlledTunnel>();
        auto *activationStrategy = activationBackend.get();
        activationStrategy->delayedConnect = true;
        TunnelManager activation(std::move(activationBackend));
        activation.Save(Example("activation"));
        activation.Connect(Example("activation"));
        assert(activation.PendingProfile() == "activation");
        activation.Advance();
        assert(activation.PendingProfile() == "activation");
        activationStrategy->fake.SetStatus("activation", Status::connected);
        activation.Advance();
        assert(!activation.PendingProfile());
        activationStrategy->fake.Disconnect("activation");
        activation.Connect(Example("activation"));
        activationStrategy->fake.Disconnect("activation");
        Rejects([&] { activation.Advance(); });
        assert(!activation.PendingProfile());

        auto timeoutBackend = std::make_unique<ControlledTunnel>();
        timeoutBackend->fake.Save(p);
        timeoutBackend->fake.Save(Example("timeout"));
        timeoutBackend->fake.Connect(p.id);
        timeoutBackend->delayedDisconnect = true;
        TunnelManager timeout(std::move(timeoutBackend), std::make_shared<AppLogger>(), std::chrono::milliseconds(0));
        Rejects([&] { timeout.Connect(Example("timeout")); });
        assert(!timeout.PendingProfile());

        // Polling does not show activity; foreground work and observed transitions do.
        AppSnapshot activity;
        activity.busy = true;
        assert(!activity.HasActivity());
        activity.foregroundBusy = true;
        assert(activity.HasActivity());
        activity.foregroundBusy = false;
        activity.pendingProfile = "next";
        assert(activity.HasActivity());
        activity.pendingProfile.reset();
        Models::AppTunnelInfo transition{};
        transition.status.value = Status::connecting;
        activity.tunnels.push_back(transition);
        activity.tunnelAvailable = true;
        assert(activity.HasActivity());
        activity.tunnels[0].status.value = Status::disconnecting;
        assert(activity.HasActivity());
        activity.tunnels[0].status.value = Status::connected;
        assert(!activity.HasActivity());

        // Record background errors once, preserve actual availability on cleanup failure, and log recovery/shutdown.
        std::vector<std::string> messages;
        auto logger = std::make_shared<AppLogger>([&](LogLevel, const std::string &, const std::string &message) {
            messages.push_back(message);
        });
        {
            auto loggingBackend = std::make_unique<ControlledTunnel>();
            auto *backend = loggingBackend.get();
            backend->failFetch = true;
            AppSession logged(std::make_unique<FileProfileRepository>(root / "logging"), importer, std::move(loggingBackend), logger);
            Wait(logged);
            const auto count = messages.size();
            logged.Refresh();
            Wait(logged);
            assert(messages.size() == count);
            backend->failFetch = false;
            backend->fake.Save(Example("orphan"));
            backend->failRemove = true;
            logged.Refresh();
            Wait(logged);
            assert(logged.Snapshot().tunnelAvailable);
            assert(logged.Snapshot().tunnelError.empty());
            assert(!logged.Snapshot().reconciliationError.empty());
            backend->failRemove = false;
            logged.Refresh();
            Wait(logged);
            assert(logged.Snapshot().reconciliationError.empty());
        }
        const auto containsLog = [&](const std::string &part) {
            return std::any_of(messages.begin(), messages.end(), [&](const auto &message) { return message.find(part) != std::string::npos; });
        };
        assert(containsLog("Reload local profiles"));
        assert(containsLog("Unable to fetch tunnel state"));
        assert(containsLog("Tunnel observation recovered"));
        assert(containsLog("Unable to remove orphaned profile orphan"));
        assert(containsLog("Profile reconciliation recovered"));
        assert(containsLog("Finished application session"));

        auto failed = std::make_unique<ControlledTunnel>();
        auto *sessionStrategy = failed.get();
        failed->failConnect = true;
        AppSession session(std::make_unique<FileProfileRepository>(root / "profiles"), importer, std::move(failed));
        Wait(session);
        assert(session.Snapshot().loaded);
        assert(session.Snapshot().profiles.size() == 2);
        assert(session.Snapshot().profiles.at(0).primaryModuleType->value == Partout::Models::ModuleType::Provider);
        session.Connect(p.id);
        Wait(session);
        assert(!session.Snapshot().error.empty());
        assert(session.Snapshot().errorContext == AppErrorContext::tunnel);
        assert(session.Snapshot().tunnels.at(0).status.value == Status::disconnected);
        session.ClearError();
        // Failed files do not prevent the rest of a batch being processed.
        const auto another = root / "another.conf";
        std::ofstream(another) << "another configuration";
        {
            auto backend = std::make_unique<ControlledTunnel>();
            auto *registration = backend.get();
            AppSession imported(std::make_unique<FileProfileRepository>(root / "registration"), importer, std::move(backend));
            Wait(imported);
            imported.Import({config});
            Wait(imported);
            assert(imported.Snapshot().error.empty());
            assert(registration->events == std::vector<std::string>{"save:imported"});
            assert(imported.Snapshot().tunnels.at(0).status.value == Status::disconnected);
            imported.Connect("imported");
            Wait(imported);
            assert((registration->events == std::vector<std::string>{"save:imported", "connect:imported"}));
            registration->failSave = true;
            imported.Import({another});
            Wait(imported);
            assert(!imported.Snapshot().error.empty());
            assert(imported.Snapshot().errorContext == AppErrorContext::tunnel);
            assert(FileProfileRepository(root / "registration").Fetch().size() == 2);
            registration->failSave = false;
            imported.Load();
            Wait(imported);
            assert(imported.Snapshot().error.empty());
            assert(imported.Snapshot().tunnels.size() == 2);
            assert(std::count(registration->events.begin(), registration->events.end(), "save:imported") == 1);
            assert(std::count(registration->events.begin(), registration->events.end(), "save:batch-id") == 2);
        }
        // Import success is independent of Windows VPN-state availability.
        auto unavailable = std::make_unique<ControlledTunnel>();
        auto *unavailableStrategy = unavailable.get();
        unavailable->failFetch = true;
        AppSession offline(std::make_unique<FileProfileRepository>(root / "offline"), importer, std::move(unavailable));
        Wait(offline);
        // A transient startup observation failure is not a failed user action.
        assert(offline.Snapshot().loaded);
        assert(offline.Snapshot().error.empty());
        assert(!offline.Snapshot().tunnelError.empty());
        assert(!offline.Snapshot().tunnelAvailable);
        unavailableStrategy->failFetch = false;
        offline.Refresh();
        Wait(offline);
        assert(offline.Snapshot().error.empty());
        assert(offline.Snapshot().tunnelError.empty());
        assert(offline.Snapshot().tunnelAvailable);
        unavailableStrategy->failFetch = true;
        offline.Import({another});
        Wait(offline);
        assert(offline.Snapshot().error.empty());
        assert(!offline.Snapshot().tunnelError.empty());
        assert(!offline.Snapshot().tunnelAvailable);
        assert(offline.Snapshot().profiles.size() == 1);
        assert(FileProfileRepository(root / "offline").Fetch().size() == 1);
        offline.Import({root / "missing.conf"});
        Wait(offline);
        assert(!offline.Snapshot().error.empty());
        assert(offline.Snapshot().errorContext == AppErrorContext::import);
        offline.Remove({"batch-id"});
        Wait(offline);
        assert(offline.Snapshot().error.empty());
        assert(offline.Snapshot().profiles.empty());
        assert(FileProfileRepository(root / "offline").Fetch().empty());
        // A registration left during an outage is reconciled on recovery.
        unavailableStrategy->fake.Save(Example("batch-id"));
        offline.ClearError();
        unavailableStrategy->failFetch = false;
        offline.Refresh();
        Wait(offline);
        assert(offline.Snapshot().tunnelError.empty());
        assert(offline.Snapshot().tunnelAvailable);
        assert(offline.Snapshot().tunnels.empty());
        // Startup also reconciles registrations left by a previous process.
        auto orphaned = std::make_unique<ControlledTunnel>();
        orphaned->fake.Save(Example("orphaned"));
        AppSession restarted(std::make_unique<FileProfileRepository>(root / "offline"), importer, std::move(orphaned));
        Wait(restarted);
        assert(restarted.Snapshot().tunnels.empty());
        // Failed local loading is not evidence that all profiles were deleted.
        auto corruptRepository = std::make_unique<FileProfileRepository>(root / "corrupt");
        std::ofstream(root / "corrupt" / "objects" / "broken.json") << "invalid";
        auto retained = std::make_unique<ControlledTunnel>();
        retained->fake.Save(Example("retained"));
        AppSession corrupt(std::move(corruptRepository), importer, std::move(retained));
        Wait(corrupt);
        assert(!corrupt.Snapshot().loaded);
        assert(!corrupt.Snapshot().error.empty());
        assert(corrupt.Snapshot().tunnels.size() == 1);
        session.Import({root / "missing.conf", another});
        Wait(session);
        assert(!session.Snapshot().error.empty());
        assert(session.Snapshot().errorContext == AppErrorContext::import);
        assert(session.Snapshot().profiles.size() == 3);
        session.Remove({"imported", "batch-id"});
        Wait(session);
        assert(session.Snapshot().profiles.size() == 1);
        FileProfileRepository reopened(root / "profiles");
        assert(reopened.Fetch().size() == 1);
        assert(reopened.Fetch().at(0).id == p.id);

        // Row toggles use observed state and reject unavailable or busy actions.
        sessionStrategy->fake.Save(Example("broken-orphan"));
        sessionStrategy->observationErrors.emplace("broken-orphan", "Invalid handle");
        sessionStrategy->observationErrors.emplace(p.id, "Invalid handle");
        session.Refresh();
        Wait(session);
        assert(session.Snapshot().tunnelAvailable);
        assert(session.Snapshot().tunnelError.empty());
        assert(session.Snapshot().reconciliationError.empty());
        assert(session.Snapshot().tunnelObservationErrors.size() == 2);
        assert(!TunnelObservable::StateForProfile(session.Snapshot(), p.id).canInteract);
        sessionStrategy->observationErrors.erase(p.id);
        session.Refresh();
        Wait(session);
        assert(TunnelObservable::StateForProfile(session.Snapshot(), p.id).canInteract);
        assert(session.Snapshot().tunnelObservationErrors.size() == 1);
        const auto retainedRegistrations = sessionStrategy->fake.Fetch();
        assert(std::any_of(retainedRegistrations.begin(), retainedRegistrations.end(), [](const auto &info) {
            return info.id == "broken-orphan";
        }));
        TunnelObservable toggle(session);
        sessionStrategy->failConnect = false;
        toggle.SetEnabled(p.id, true);
        Wait(session);
        auto toggleState = TunnelObservable::StateForProfile(session.Snapshot(), p.id);
        assert(toggleState.isOn && toggleState.canInteract);
        toggle.SetEnabled(p.id, false);
        Wait(session);
        toggleState = TunnelObservable::StateForProfile(session.Snapshot(), p.id);
        assert(!toggleState.isOn && toggleState.canInteract);
        auto unavailableState = session.Snapshot();
        unavailableState.tunnelAvailable = false;
        assert(!TunnelObservable::StateForProfile(unavailableState, p.id).canInteract);
        unavailableState = session.Snapshot();
        unavailableState.tunnelObservationErrors.emplace(p.id, "Invalid handle");
        assert(!TunnelObservable::StateForProfile(unavailableState, p.id).canInteract);
        unavailableState.tunnelObservationErrors.clear();
        unavailableState.tunnelObservationErrors.emplace("broken-orphan", "Invalid handle");
        assert(TunnelObservable::StateForProfile(unavailableState, p.id).canInteract);
        unavailableState = session.Snapshot();
        unavailableState.foregroundBusy = true;
        assert(!TunnelObservable::StateForProfile(unavailableState, p.id).canInteract);
        assert(!TunnelObservable::StateForProfile(session.Snapshot(), "missing").canInteract);
        auto transitioning = session.Snapshot();
        transitioning.tunnels.at(0).status.value = Status::connecting;
        transitioning.tunnels.at(0).isEnabled = true;
        assert(TunnelObservable::StateForProfile(transitioning, p.id).canInteract);
        transitioning.tunnels.at(0).status.value = Status::disconnecting;
        assert(!TunnelObservable::StateForProfile(transitioning, p.id).canInteract);
        transitioning.tunnels.at(0).id = "another-active-profile";
        assert(TunnelObservable::StateForProfile(transitioning, p.id).canInteract);
        sessionStrategy->failConnect = true;
        toggle.SetEnabled(p.id, true);
        Wait(session);
        assert(!session.Snapshot().error.empty());
        assert(!TunnelObservable::StateForProfile(session.Snapshot(), p.id).isOn);
        session.ClearError();
        sessionStrategy->failConnect = false;

        auto gate = std::make_shared<Gate>();
        auto entered = gate->entered.get_future();
        AppSession queued(std::make_unique<FileProfileRepository>(root / "profiles"),
                          importer, std::make_unique<BlockingTunnel>(gate));
        Wait(queued);
        queued.Connect(p.id);
        assert(entered.wait_for(std::chrono::seconds(5)) == std::future_status::ready);
        queued.Disconnect(p.id);
        assert(queued.Snapshot().busy);
        assert(!TunnelObservable::StateForProfile(queued.Snapshot(), p.id).canInteract);
        gate->release.set_value();
        Wait(queued);
        assert(queued.Snapshot().error.empty());
        assert(queued.Snapshot().tunnels.at(0).status.value == Status::disconnected);

        auto delayed = std::make_unique<ControlledTunnel>();
        delayed->fake.Save(p);
        delayed->fake.Connect(p.id);
        delayed->delayedDisconnect = true;
        auto *delayedStrategy = delayed.get();
        AppSession removal(std::make_unique<FileProfileRepository>(root / "profiles"),
                           importer, std::move(delayed));
        Wait(removal);
        removal.Remove({p.id});
        Wait(removal);
        assert(removal.Snapshot().error.empty());
        assert(removal.Snapshot().tunnelError.empty());
        assert(removal.Snapshot().tunnelAvailable);
        assert(!removal.Snapshot().reconciliationError.empty());
        assert(removal.Snapshot().profiles.empty());
        assert(reopened.Fetch().empty());
        // Keep the Windows registration until disconnect actually finishes.
        assert(delayedStrategy->fake.Fetch().size() == 1);
        delayedStrategy->fake.SetStatus(p.id, Status::disconnected);
        removal.Refresh();
        Wait(removal);
        assert(removal.Snapshot().tunnelError.empty());
        assert(removal.Snapshot().tunnels.empty());
        assert(removal.Snapshot().reconciliationError.empty());
    } catch (...) {
        std::filesystem::remove_all(root);
        throw;
    }
    std::filesystem::remove_all(root);
    std::cout << "Persistence, import, reconciliation and failure-state checks passed.\n";
}
