// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "business/profiles.h"
#include "context/import_result.h"
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
    bool failFetch = false;
    bool delayedDisconnect = false;
    std::vector<Models::AppTunnelInfo> Fetch() override {
        if (failFetch) throw std::runtime_error("VPN state unavailable");
        return fake.Fetch();
    }
    void Save(const Profile &p) override {
        fake.Save(p);
    }
    void Connect(const std::string &id) override {
        if (failConnect) throw std::runtime_error("Connection rejected");
        fake.Connect(id);
    }
    void Disconnect(const std::string &id) override {
        if (delayedDisconnect) fake.SetStatus(id, Status::disconnecting);
        else fake.Disconnect(id);
    }
    void Remove(const std::string &id) override {
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
        tunnel.Connect(p);
        assert(tunnel.Fetch().at(0).status.value == Status::connected);
        Rejects([&] {
            tunnel.Connect(Example("second"));
        });
        strategy->delayedDisconnect = true;
        Rejects([&] {
            tunnel.Remove(p.id);
        });
        assert(tunnel.Fetch().size() == 1);
        strategy->fake.SetStatus(p.id, Status::disconnected);
        tunnel.Remove(p.id);
        assert(tunnel.Fetch().empty());

        auto failed = std::make_unique<ControlledTunnel>();
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
        // Import success is independent of Windows VPN-state availability.
        auto unavailable = std::make_unique<ControlledTunnel>();
        auto *unavailableStrategy = unavailable.get();
        unavailable->failFetch = true;
        AppSession offline(std::make_unique<FileProfileRepository>(root / "offline"), importer, std::move(unavailable));
        Wait(offline);
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

        auto gate = std::make_shared<Gate>();
        auto entered = gate->entered.get_future();
        AppSession queued(std::make_unique<FileProfileRepository>(root / "profiles"),
                          importer, std::make_unique<BlockingTunnel>(gate));
        Wait(queued);
        queued.Connect(p.id);
        assert(entered.wait_for(std::chrono::seconds(5)) == std::future_status::ready);
        queued.Disconnect(p.id);
        assert(queued.Snapshot().busy);
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
        assert(!removal.Snapshot().tunnelError.empty());
        assert(removal.Snapshot().profiles.empty());
        assert(reopened.Fetch().empty());
        // Keep the Windows registration until disconnect actually finishes.
        assert(delayedStrategy->fake.Fetch().size() == 1);
        delayedStrategy->fake.SetStatus(p.id, Status::disconnected);
        removal.Refresh();
        Wait(removal);
        assert(removal.Snapshot().tunnelError.empty());
        assert(removal.Snapshot().tunnels.empty());
    } catch (...) {
        std::filesystem::remove_all(root);
        throw;
    }
    std::filesystem::remove_all(root);
    std::cout << "Persistence, import, reconciliation and failure-state checks passed.\n";
}
