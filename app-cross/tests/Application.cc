// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "business/managers/ProfileManager.h"
#include "business/strategy/FileProfileRepository.h"
#include "business/extensions/ModelsExtensions.h"
#include "context/ContextExtensions.h"
#include "context/ContextExtensions.h"
#include <partout/tunnel/Tunnel.h>
#include "business/strategy/FakeTunnelStrategy.h"
#include "business/managers/AppSession.h"
#include "observables/ProfileObservable.h"
#include "observables/TunnelObservable.h"
#include "ui/platform/ModalConfigurationPicker.h"
#include "ui/extensions/ModelsExtensions.h"
#include <algorithm>
#include <cassert>
#include <fstream>
#include <chrono>
#include <iostream>
#include <future>
#ifdef _MSC_VER
#include <crtdbg.h>
#endif

namespace {
Passepartout::Profile Example(std::string id = "test-id", std::string name = "Example") {
    Passepartout::Profile p{};
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
class ControlledTunnel final : public Partout::TunnelStrategy {
public:
    Passepartout::FakeTunnelStrategy fake;
    bool fail_connect = false;
    bool delayed_connect = false;
    bool fail_fetch = false;
    bool delayed_disconnect = false;
    bool fail_disconnect = false;
    bool fail_remove = false;
    bool fail_save = false;
    bool fail_preferences = false;
    bool lose_observation_on_disconnect = false;
    unsigned removal_attempts = 0;
    std::map<std::string, std::string> observation_errors;
    std::vector<std::string> events;
    void ApplyPreferences(const Passepartout::Models::AppPreferences &) {
        events.push_back("preferences");
        if (fail_preferences) throw std::runtime_error("Preferences rejected");
    }

    std::vector<Partout::Models::TunnelSnapshot> Fetch() override {
        if (fail_fetch) throw std::runtime_error("VPN state unavailable");
        auto result = fake.Fetch();
        result.erase(std::remove_if(result.begin(), result.end(), [&](const auto &info) {
            return observation_errors.find(info.id) != observation_errors.end();
        }), result.end());
        return result;
    }

    std::map<std::string, std::string> ObservationErrors() const override {
        return observation_errors;
    }

    void Save(const Passepartout::Profile &p) override {
        events.push_back("save:" + p.id);
        if (fail_save) throw std::runtime_error("Registration rejected");
        fake.Save(p);
    }

    void Connect(const std::string &id) override {
        events.push_back("connect:" + id);
        if (fail_connect) throw std::runtime_error("Connection rejected");
        if (delayed_connect) fake.SetStatus(id, Partout::Models::TunnelStatus::activating);
        else fake.Connect(id);
    }

    void Disconnect(const std::string &id) override {
        events.push_back("disconnect:" + id);
        if (fail_disconnect) throw std::runtime_error("Disconnect rejected");
        const auto states = fake.Fetch();
        const bool exists = std::any_of(states.begin(), states.end(), [&](const auto &state) { return state.id == id; });
        if (delayed_disconnect && exists) fake.SetStatus(id, Partout::Models::TunnelStatus::deactivating);
        else fake.Disconnect(id);
        if (lose_observation_on_disconnect) observation_errors[id] = "Invalid handle after disconnect";
    }

    void Remove(const std::string &id) override {
        ++removal_attempts;
        if (fail_remove) throw std::runtime_error("Removal rejected");
        fake.Remove(id);
    }
};
struct Gate {
    std::promise<void> entered;
    std::promise<void> release;
};
class FailingImportRepository final : public Passepartout::ProfileRepository {
public:
    bool fail_remove = false;
    std::vector<Passepartout::Profile> stored;
    std::vector<Passepartout::Profile> Fetch() override {
        return stored;
    }

    void Save(const Passepartout::Profile &profile) override {
        stored.push_back(profile);
        throw std::runtime_error("Index commit failed");
    }

    void Remove(const std::string &) override {
        if (fail_remove) throw std::runtime_error("Local rollback failed");
        stored.clear();
    }
};
class BlockingTunnel final : public Partout::TunnelStrategy {
public:
    explicit BlockingTunnel(std::shared_ptr<Gate> gate) : gate_(std::move(gate)) {}

    std::vector<Partout::Models::TunnelSnapshot> Fetch() override {
        return fake_.Fetch();
    }

    void Save(const Passepartout::Profile &p) override {
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
    Passepartout::FakeTunnelStrategy fake_;
};
void Wait(Passepartout::AppSession &session) {
    assert(session.WaitIdle(std::chrono::seconds(5)));
}
struct Cancellation {
    std::mutex mutex;
    std::condition_variable changed;
    bool entered = false;
    bool canceled = false;
    void Block() {
        std::unique_lock lock(mutex);
        entered = true;
        changed.notify_all();
        changed.wait(lock, [&] { return canceled; });
        throw std::runtime_error("Canceled");
    }

    void WaitForEntry() {
        std::unique_lock lock(mutex);
        assert(changed.wait_for(lock, std::chrono::seconds(2), [&] { return entered; }));
    }

    void Cancel() noexcept {
        std::lock_guard lock(mutex);
        canceled = true;
        changed.notify_all();
    }
};
class CancelableTunnel final : public Partout::TunnelStrategy {
public:
    explicit CancelableTunnel(std::shared_ptr<Cancellation> cancellation) : cancellation_(std::move(cancellation)) {}

    std::vector<Partout::Models::TunnelSnapshot> Fetch() override {
        cancellation_->Block();
        return {};
    }

    void Save(const Passepartout::Profile &) override {}

    void Connect(const std::string &) override {}

    void Disconnect(const std::string &) override {}

    void Remove(const std::string &) override {}

    void Cancel() noexcept override {
        cancellation_->Cancel();
    }
private:
    std::shared_ptr<Cancellation> cancellation_;
};
class CancelableFiles final : public Passepartout::ConfigurationFiles {
public:
    explicit CancelableFiles(std::shared_ptr<Cancellation> cancellation)
        : Passepartout::ConfigurationFiles({"unused"}), cancellation_(std::move(cancellation)) {}

    Passepartout::ConfigurationSource Read(std::size_t) const override {
        cancellation_->Block();
        return {};
    }

    void Cancel() const noexcept override {
        cancellation_->Cancel();
    }
private:
    std::shared_ptr<Cancellation> cancellation_;
};
void TestShutdown(const std::filesystem::path &root) {
    const auto tunnel = std::make_shared<Cancellation>();
    {
        Passepartout::AppSession session(std::make_unique<Passepartout::FileProfileRepository>(root / "cancel-tunnel"), {},
            std::make_unique<Partout::Tunnel>(std::make_unique<CancelableTunnel>(tunnel)));
        tunnel->WaitForEntry();
    }
    assert(tunnel->canceled);
    const auto files = std::make_shared<Cancellation>();
    {
        Passepartout::AppSession session(std::make_unique<Passepartout::FileProfileRepository>(root / "cancel-files"), {},
            std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>()));
        Wait(session);
        session.ImportFiles(std::make_shared<CancelableFiles>(files));
        files->WaitForEntry();
    }
    assert(files->canceled);
}

void TestPreferencesRetry(const std::filesystem::path &root) {
    auto repository = std::make_unique<Passepartout::FileProfileRepository>(root / "preferences-retry");
    repository->Save(Example());
    auto strategy = std::make_unique<ControlledTunnel>();
    auto *backend = strategy.get();
    Passepartout::AppSession session(std::move(repository), {}, std::make_unique<Partout::Tunnel>(std::move(strategy)),
        std::make_shared<Passepartout::AppLogger>(), std::make_unique<Passepartout::MemoryProfileJournal>(),
        std::chrono::seconds(1), [backend](const auto &preferences) { backend->ApplyPreferences(preferences); });
    Wait(session);
    backend->events.clear();
    backend->fail_preferences = true;
    session.ApplyPreferences({});
    Wait(session);
    assert(!session.Snapshot().error.empty());
    session.Connect("test-id");
    Wait(session);
    assert(!session.Snapshot().error.empty());
    assert((backend->events == std::vector<std::string>{"preferences", "preferences"}));
    backend->fail_preferences = false;
    session.Connect("test-id");
    Wait(session);
    assert(session.Snapshot().error.empty());
    assert((backend->events == std::vector<std::string>{"preferences", "preferences", "preferences", "connect:test-id"}));
}

void TestRemovalObservation() {
    auto strategy = std::make_unique<ControlledTunnel>();
    auto *backend = strategy.get();
    backend->fake.Save(Example());
    backend->fake.Connect("test-id");
    backend->observation_errors["test-id"] = "Unavailable";
    Partout::Tunnel tunnel(std::move(strategy));
    Rejects([&] {
        tunnel.Remove("test-id");
    });
    assert(backend->removal_attempts == 0 && backend->events.empty());
    backend->observation_errors.clear();
    backend->lose_observation_on_disconnect = true;
    Rejects([&] {
        tunnel.Remove("test-id");
    });
    assert(backend->removal_attempts == 0);
    assert(backend->fake.Fetch().size() == 1);
    backend->observation_errors.clear();
    tunnel.Remove("test-id");
    assert(backend->removal_attempts == 1 && backend->fake.Fetch().empty());
}

void TestPendingActivation(const std::filesystem::path &root) {
    auto repository = std::make_unique<Passepartout::FileProfileRepository>(root / "pending");
    repository->Save(Example("first"));
    repository->Save(Example("second"));
    auto strategy = std::make_unique<ControlledTunnel>();
    auto *backend = strategy.get();
    backend->delayed_disconnect = true;
    backend->delayed_connect = true;
    Passepartout::AppSession session(
        std::move(repository), {}, std::make_unique<Partout::Tunnel>(std::move(strategy))
    );
    Wait(session);
    backend->fake.Connect("first");
    session.Connect("second");
    Wait(session);
    assert(session.Snapshot().pending_profile == "second");
    assert(!Passepartout::TunnelObservable::StateForProfile(session.Snapshot(), "second").can_interact);
    session.Refresh();
    Wait(session);
    assert(session.Snapshot().pending_profile == "second");
    backend->fake.Disconnect("first");
    session.Refresh();
    Wait(session);
    assert(session.Snapshot().pending_profile == "second");
    backend->fake.Connect("second");
    session.Refresh();
    Wait(session);
    assert(!session.Snapshot().pending_profile);
    assert(Passepartout::TunnelObservable::StateForProfile(session.Snapshot(), "second").can_interact);

    // Failed activation clears the UI request and retains the tunnel error context.
    backend->delayed_disconnect = false;
    session.Connect("first");
    Wait(session);
    assert(session.Snapshot().pending_profile == "first");
    backend->fake.Disconnect("first");
    session.Refresh();
    Wait(session);
    assert(!session.Snapshot().pending_profile);
    assert(!session.Snapshot().error.empty());
    assert(session.Snapshot().error_context == Passepartout::AppErrorContext::tunnel);

    session.Connect("second");
    Wait(session);
    assert(session.Snapshot().pending_profile == "second");
    session.Disconnect("second");
    Wait(session);
    assert(!session.Snapshot().pending_profile && session.Snapshot().error.empty());
    session.Connect("second");
    Wait(session);
    session.Remove({"second"});
    Wait(session);
    assert(!session.Snapshot().pending_profile && session.Snapshot().error.empty());
    session.Refresh();
    Wait(session);
    assert(session.Snapshot().tunnels.size() == 1);
    assert(session.Snapshot().tunnels.front().id == "first");
}

void TestRemovalTargets(const std::filesystem::path &root) {
    const auto directory = root / "removal-targets";
    auto repository = std::make_unique<Passepartout::FileProfileRepository>(directory);
    repository->Save(Example("first"));
    repository->Save(Example("second"));
    Passepartout::AppSession session(std::move(repository), {}, std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>()));
    Passepartout::ProfileObservable profiles(session);
    Wait(session);
    const std::vector<std::string> targets{"first", "second"};
    auto state = profiles.Snapshot();
    assert(Passepartout::ProfileObservable::CanRemove(state, targets));
    assert(!Passepartout::ProfileObservable::CanRemove(state, {}));
    assert(!Passepartout::ProfileObservable::CanRemove(state, {"missing"}));
    state.busy = true;
    assert(Passepartout::ProfileObservable::CanRemove(state, targets)); // Background polling is not a conflicting action.
    state.foreground_busy = true;
    assert(!Passepartout::ProfileObservable::CanRemove(state, targets));
    state.foreground_busy = false;
    state.pending_profile = "first";
    assert(!Passepartout::ProfileObservable::CanRemove(state, targets));
    state.pending_profile.reset();
    state.loaded = false;
    assert(!Passepartout::ProfileObservable::CanRemove(state, targets));

    // A stale target invalidates the whole batch before any local mutation.
    session.Remove({"first", "missing"});
    Wait(session);
    assert(!profiles.Snapshot().error.empty());
    assert(Passepartout::FileProfileRepository(directory).Fetch().size() == 2);
    profiles.ClearError();
    profiles.Remove({"first", "first"});
    Wait(session);
    assert(profiles.Snapshot().error.empty());
    assert(Passepartout::FileProfileRepository(directory).Fetch().size() == 1);
    // Confirmation/menu targets are revalidated without deleting a new selection.
    profiles.Remove(targets);
    Wait(session);
    assert(profiles.Snapshot().profiles.front().id == "second");
}

void TestModalPicker() {
    Passepartout::ModalConfigurationPicker *active = nullptr;
    bool cancel = false;
    bool dismiss = false;
    Passepartout::ModalConfigurationPicker picker([&]() -> Passepartout::ConfigurationPickerResult {
        // Simulate timer events dispatched by ShowModal's nested event loop.
        assert(!active->Poll());
        assert(!active->Poll());
        if (cancel) active->Cancel();
        if (dismiss) return {};
        return {std::make_shared<Passepartout::ConfigurationFiles>(
            std::vector<std::filesystem::path>{"selected.conf"}), false};
    });
    active = &picker;
    picker.Start();
    auto result = picker.Poll();
    assert(result && result->files && result->files->paths.front() == "selected.conf");
    assert(!picker.Poll());
    dismiss = true;
    picker.Start();
    result = picker.Poll();
    assert(result && !result->files && !result->failed);
    assert(!picker.Poll());
    dismiss = false;
    cancel = true;
    picker.Start();
    assert(!picker.Poll());
    cancel = false;
    picker.Start();
    // A new modal selection must discard an unconsumed previous result.
    picker.Start();
    assert(picker.Poll()->files);
}

void TestSelectionFailures(const std::filesystem::path &root) {
    const auto valid = root / "valid.conf";
    const auto invalid = root / "invalid.conf";
    std::ofstream(valid) << "valid";
    std::ofstream(invalid) << "invalid syntax";
    std::vector<std::size_t> visited;
    auto selected = Passepartout::Configuration::CollectFiles(5, [&](std::size_t index) {
        visited.push_back(index);
        if (index == 1) return valid;
        if (index == 3) return invalid;
        throw std::runtime_error("Native staging failed");
    });
    assert(visited.size() == 5);
    assert(selected.paths.size() == 2 && selected.selection_failures == 3);
    Passepartout::AppSession session(std::make_unique<Passepartout::FileProfileRepository>(root / "selection-store"),
        [](const std::string &text, const std::string &) {
            if (text != "valid") throw std::runtime_error("Invalid configuration");
            return Example("selected-valid");
        }, std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>()));
    Wait(session);
    session.ImportFiles(std::make_shared<Passepartout::ConfigurationFiles>(std::move(selected)));
    Wait(session);
    auto snapshot = session.Snapshot();
    assert(snapshot.profiles.size() == 1 && snapshot.profiles.front().id == "selected-valid");
    assert(snapshot.error_context == Passepartout::AppErrorContext::import);
    assert(snapshot.error.find("4 configuration(s)") != std::string::npos);
    assert(Passepartout::FileProfileRepository(root / "selection-store").Fetch().size() == 1);

    auto failed = Passepartout::Configuration::CollectFiles(2, [](std::size_t) -> std::filesystem::path {
        throw std::runtime_error("Unreadable file");
    });
    session.ImportFiles(std::make_shared<Passepartout::ConfigurationFiles>(std::move(failed)));
    Wait(session);
    assert(session.Snapshot().error.find("2 configuration(s)") != std::string::npos);
    assert(session.Snapshot().profiles.size() == 1);
    auto empty = Passepartout::Configuration::CollectFiles(0, [](std::size_t) -> std::filesystem::path {
        assert(false);
        return {};
    });
    const auto revision = session.Snapshot().revision;
    session.ImportFiles(std::make_shared<Passepartout::ConfigurationFiles>(std::move(empty)));
    assert(session.Snapshot().revision == revision);
}

void TestLargeSelection(const std::filesystem::path &root) {
    constexpr std::size_t count = 40;
    auto selected = Passepartout::Configuration::CollectFiles(count, [&](std::size_t index) {
        const auto path = root / ("batch-" + std::to_string(index) + ".conf");
        std::ofstream(path) << "batch-" << index;
        return path;
    });
    assert(selected.paths.size() == count && selected.selection_failures == 0);
    Passepartout::AppSession session(std::make_unique<Passepartout::FileProfileRepository>(root / "large-selection-store"),
        [](const std::string &text, const std::string &) {
            return Example(text);
        }, std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>()));
    Wait(session);
    session.ImportFiles(std::make_shared<Passepartout::ConfigurationFiles>(std::move(selected)));
    Wait(session);
    const auto snapshot = session.Snapshot();
    assert(snapshot.error.empty());
    assert(snapshot.profiles.size() == count);
    const auto saved = Passepartout::FileProfileRepository(root / "large-selection-store").Fetch();
    assert(saved.size() == count);
    for (std::size_t index = 0; index < count; ++index) {
        const auto id = "batch-" + std::to_string(index);
        assert(std::any_of(saved.begin(), saved.end(), [&](const auto &profile) {
            return profile.id == id;
        }));
    }
}
class TemporaryConfigurationFiles final : public Passepartout::ConfigurationFiles {
public:
    TemporaryConfigurationFiles(const std::filesystem::path &path, std::shared_ptr<std::promise<void>> destroyed)
        : Passepartout::ConfigurationFiles({path}), destroyed_(std::move(destroyed)) {}

    ~TemporaryConfigurationFiles() override {
        std::error_code error;
        std::filesystem::remove(paths.front(), error);
        destroyed_->set_value();
    }
private:
    std::shared_ptr<std::promise<void>> destroyed_;
};
void TestSelectedFiles(const std::filesystem::path &root, bool fail) {
    const auto input = root / "selected.conf";
    std::ofstream(input) << "selected configuration";
    auto gate = std::make_shared<Gate>();
    auto entered = gate->entered.get_future();
    auto destroyed = std::make_shared<std::promise<void>>();
    auto cleanup = destroyed->get_future();
    Passepartout::AppSession session(std::make_unique<Passepartout::FileProfileRepository>(root / "store"),
        [gate, fail](const std::string &text, const std::string &name) {
            assert(text == "selected configuration");
            assert(name == "selected");
            gate->entered.set_value();
            gate->release.get_future().wait();
            if (fail) throw std::runtime_error("Invalid configuration");
            return Example();
        }, std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>()));
    Wait(session);
    Passepartout::ProfileObservable observable(session);
    auto files = std::make_shared<TemporaryConfigurationFiles>(input, destroyed);
    std::weak_ptr<const Passepartout::ConfigurationFiles> lifetime = files;
    observable.ImportFiles(files);
    files.reset();
    assert(entered.wait_for(std::chrono::seconds(5)) == std::future_status::ready);
    assert(!lifetime.expired());
    assert(std::filesystem::exists(input));
    gate->release.set_value();
    Wait(session);
    assert(cleanup.wait_for(std::chrono::seconds(5)) == std::future_status::ready);
    assert(lifetime.expired());
    assert(!std::filesystem::exists(input));
    assert(session.Snapshot().error.empty() != fail);
    assert(session.Snapshot().profiles.size() == (fail ? 0 : 1));
    observable.ClearError();
    const auto revision = observable.Snapshot().revision;
    observable.ImportFiles(nullptr);
    observable.ImportFiles(std::make_shared<Passepartout::ConfigurationFiles>(std::vector<std::filesystem::path>{}));
    assert(observable.Snapshot().revision == revision);
    observable.ImportFailed();
    Wait(session);
    assert(!observable.Snapshot().error.empty());
    assert(observable.Snapshot().error_context == Passepartout::AppErrorContext::import);
}
}

using namespace Passepartout;
int main() {
#ifdef _MSC_VER
    _set_error_mode(_OUT_TO_STDERR);
    _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
#endif
    TestModalPicker();
    TestRemovalObservation();
    {
        auto strategy = std::make_unique<ControlledTunnel>();
        auto *control = strategy.get();
        control->fake.Save(Example("broken"));
        control->observation_errors.emplace("broken", "Invalid handle");
        Partout::Tunnel manager(std::move(strategy));
        manager.Save(Example("healthy"));
        manager.Connect(Example("healthy"));
        assert((control->events == std::vector<std::string>{"save:healthy", "connect:healthy"}));
        assert(manager.Fetch().at(0).status.value == Partout::Models::TunnelStatus::active);
        assert(manager.ObservationErrors().count("broken") == 1);
        Rejects([&] { manager.Connect(Example("broken")); });
        assert(control->events.size() == 2);
    }
    auto constants = Constants::Load();
    assert(constants.containers.local == "Local");
    assert(Profiles::Directory("root", constants, DefaultCrossConstants, false) == std::filesystem::path("root/local"));
    assert(Profiles::Directory("root", constants, DefaultCrossConstants, true) == std::filesystem::path("root/demo-local"));
    constants.containers.local = "Testing";
    auto frontend_constants = DefaultCrossConstants;
    frontend_constants.storage.demo_prefix = "preview-";
    assert(Profiles::Directory("root", constants, frontend_constants, true) == std::filesystem::path("root/preview-testing"));
    constants.containers.local = "../outside";
    Rejects([&] { Profiles::Directory("root", constants, frontend_constants, false); });
    const auto imported = Example();
    const auto success = Partout::Json{{"payload", imported.ToJson()}};
    assert(Imports::DecodeResult(success.Encode().c_str()) == imported);
    auto explicit_success = success;
    explicit_success.Set("code", nullptr);
    assert(Imports::DecodeResult(explicit_success.Encode().c_str()) == imported);
    auto failure = success;
    failure.Set("code", "parsing");
    Rejects([&] { Imports::DecodeResult(failure.Encode().c_str()); });
    Rejects([] { Imports::DecodeResult(nullptr); });
    Rejects([] { Imports::DecodeResult("not JSON"); });
    Rejects([] { Imports::DecodeResult("{}"); });
    Rejects([&] { Imports::DecodeResult(imported.ToJson().Encode().c_str()); });
    const auto root = std::filesystem::temp_directory_path() /
        ("passepartout-test-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    std::filesystem::create_directories(root);
    try {
        TestRemovalTargets(root);
        TestPendingActivation(root);
        TestShutdown(root);
        TestPreferencesRetry(root);
        const auto selection_root = root / "selection";
        std::filesystem::create_directories(selection_root);
        TestSelectionFailures(selection_root);
        TestLargeSelection(selection_root);
        for (const auto fail : {false, true}) {
            const auto selected = root / (fail ? "selected-failure" : "selected-success");
            std::filesystem::create_directories(selected);
            TestSelectedFiles(selected, fail);
        }
        const auto storage_root = root / "layout";
        FileProfileRepository storage(storage_root);
        assert(storage.Fetch().empty());
        assert(Partout::Json::Parse(Profiles::ReadConfiguration(storage_root / "index.json")).At("version") == 1);
        auto earlier = Example("earlier", "ALPHA");
        earlier.userInfo = {{"lastUpdate", 1}, {"fingerprint", "first"}};
        auto later = Example("later", "alpha");
        later.userInfo = {{"lastUpdate", "2"}, {"fingerprint", "second"}};
        storage.Save(Example("zulu", "Zulu"));
        storage.Save(earlier);
        storage.Save(later);
        assert(std::filesystem::exists(storage_root / "objects" / "later.json"));
        assert(storage.Fetch().at(0).id == "later");
        auto index = Partout::Json::Parse(Profiles::ReadConfiguration(storage_root / "index.json"));
        assert(index.At("profiles").Elements().at(0).At("fingerprint") == "second");
        assert(index.At("profiles").Elements().at(0).At("lastUpdate") == "2");
        // A valid index defines fetch order, as on Android.
        auto entries = index.At("profiles").Elements();
        std::reverse(entries.begin(), entries.end());
        index.Set("profiles", entries);
        std::ofstream(storage_root / "index.json") << index.Encode();
        assert(storage.Fetch().at(0).id == "zulu");
        // Interrupted index writes and missing indexes recover from objects.
        std::ofstream(storage_root / "index.json") << "broken index";
        assert(storage.Fetch().at(0).id == "later");
        std::filesystem::remove(storage_root / "index.json");
        assert(storage.Fetch().size() == 3);
        std::ofstream(storage_root / "objects" / "unindexed.json") << Example("unindexed", "Beta").ToJson().Encode();
        assert(storage.Fetch().size() == 4);
        // Missing indexed objects must not be silently treated as deletion.
        std::filesystem::remove(storage_root / "objects" / "unindexed.json");
        Rejects([&] { storage.Fetch(); });
        storage.Remove("unindexed");
        assert(storage.Fetch().size() == 3);
        storage.Remove("later");
        assert(FileProfileRepository(storage_root).Fetch().size() == 2);
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
        {
            auto repository = std::make_unique<FailingImportRepository>();
            auto *storage = repository.get();
            ProfileManager transaction(std::move(repository), importer);
            transaction.Load();
            bool registered = false;
            bool rollback_attempted = false;
            Rejects([&] {
                transaction.Import(config, [&](const Profile &) { registered = true; }, [&](const std::string &) {
                    rollback_attempted = true;
                    registered = false;
                });
            });
            assert(!registered && rollback_attempted && storage->stored.empty() && transaction.Profiles().empty());
            rollback_attempted = false;
            Rejects([&] {
                transaction.Import(config, [](const Profile &) { throw std::runtime_error("Rejected"); },
                    [&](const std::string &) { rollback_attempted = true; });
            });
            // A rejected registration may have partially written native state.
            assert(rollback_attempted && storage->stored.empty());
            storage->fail_remove = true;
            std::string error;
            try {
                transaction.Import(config, [](const Profile &) {}, [&](const std::string &) {
                    rollback_attempted = true;
                    throw std::runtime_error("Native rollback failed");
                });
            } catch (const std::exception &failure) {
                error = failure.what();
            }
            assert(rollback_attempted && transaction.Profiles().empty());
            assert(error.find("Local import rollback failed") != std::string::npos);
            assert(error.find("VPN registration rollback failed") != std::string::npos);
        }

        auto controlled = std::make_unique<ControlledTunnel>();
        auto *strategy = controlled.get();
        Partout::Tunnel tunnel(std::move(controlled));
        tunnel.Save(p);
        tunnel.Connect(p);
        assert(tunnel.Fetch().at(0).status.value == Partout::Models::TunnelStatus::active);
        tunnel.Save(Example("second"));
        tunnel.Connect(Example("second"));
        assert(strategy->fake.Fetch().at(0).status.value == Partout::Models::TunnelStatus::inactive);
        assert(strategy->fake.Fetch().at(1).status.value == Partout::Models::TunnelStatus::active);
        assert((strategy->events == std::vector<std::string>{"save:" + p.id, "connect:" + p.id,
            "save:second", "disconnect:" + p.id, "connect:second"}));
        tunnel.Connect(p);
        tunnel.Remove("second");
        strategy->delayed_disconnect = true;
        Rejects([&] {
            tunnel.Remove(p.id);
        });
        assert(tunnel.Fetch().size() == 1);
        strategy->fake.SetStatus(p.id, Partout::Models::TunnelStatus::inactive);
        tunnel.Remove(p.id);
        assert(tunnel.Fetch().empty());

        // Handover waits for observed deactivation, and a new accepted target replaces the old one.
        auto handover_backend = std::make_unique<ControlledTunnel>();
        auto *handover_strategy = handover_backend.get();
        handover_strategy->fake.Save(p);
        for (const auto *id : {"latest", "next", "failed", "cancelled", "connection-failure"})
            handover_strategy->fake.Save(Example(id));
        handover_strategy->fake.Connect(p.id);
        handover_strategy->delayed_disconnect = true;
        Partout::Tunnel handover(std::move(handover_backend));
        handover.Connect(Example("next"));
        handover.Advance();
        assert(handover_strategy->events == std::vector<std::string>{"disconnect:" + p.id});
        handover.Connect(Example("latest"));
        handover_strategy->fake.SetStatus(p.id, Partout::Models::TunnelStatus::inactive);
        handover.Advance();
        assert((handover_strategy->events == std::vector<std::string>{"disconnect:" + p.id, "connect:latest"}));
        handover_strategy->fail_disconnect = true;
        Rejects([&] { handover.Connect(Example("failed")); });
        assert(handover_strategy->fake.Fetch().at(1).status.value == Partout::Models::TunnelStatus::active);
        handover_strategy->fail_disconnect = false;
        handover.Connect(Example("cancelled"));
        handover.Disconnect("cancelled");
        handover_strategy->fake.SetStatus("latest", Partout::Models::TunnelStatus::inactive);
        handover_strategy->fake.SetStatus("cancelled", Partout::Models::TunnelStatus::inactive);
        handover.Advance();
        assert(handover_strategy->fake.Fetch().size() == 6);
        handover_strategy->fail_connect = true;
        Rejects([&] { handover.Connect(Example("connection-failure")); });
        for (const auto &state : handover.Fetch()) assert(state.status.value == Partout::Models::TunnelStatus::inactive);

        auto activation_backend = std::make_unique<ControlledTunnel>();
        auto *activation_strategy = activation_backend.get();
        activation_strategy->delayed_connect = true;
        Partout::Tunnel activation(std::move(activation_backend));
        activation.Save(Example("activation"));
        activation.Connect(Example("activation"));
        activation.Advance();
        activation_strategy->fake.SetStatus("activation", Partout::Models::TunnelStatus::active);
        activation.Advance();
        activation_strategy->fake.Disconnect("activation");
        activation.Connect(Example("activation"));
        activation_strategy->fake.Disconnect("activation");
        Rejects([&] { activation.Advance(); });

        auto timeout_backend = std::make_unique<ControlledTunnel>();
        timeout_backend->fake.Save(p);
        timeout_backend->fake.Save(Example("timeout"));
        timeout_backend->fake.Connect(p.id);
        timeout_backend->delayed_disconnect = true;
        Partout::Tunnel timeout(std::move(timeout_backend), std::chrono::milliseconds(0));
        Rejects([&] { timeout.Connect(Example("timeout")); });

        // Polling does not show activity; foreground work and observed transitions do.
        AppSnapshot activity;
        activity.busy = true;
        assert(!activity.HasActivity());
        activity.foreground_busy = true;
        assert(activity.HasActivity());
        activity.foreground_busy = false;
        activity.pending_profile = "next";
        assert(activity.HasActivity());
        activity.pending_profile.reset();
        Models::AppTunnelInfo transition{};
        transition.status.value = Status::connecting;
        activity.tunnels.push_back(transition);
        activity.tunnel_available = true;
        assert(activity.HasActivity());
        activity.tunnels[0].status.value = Status::disconnecting;
        assert(activity.HasActivity());
        activity.tunnels[0].status.value = Status::connected;
        assert(!activity.HasActivity());

        // Record background errors once, preserve actual availability on cleanup failure, and log recovery/shutdown.
        std::vector<std::string> messages;
        auto logger = std::make_shared<AppLogger>([&](LogLevel, LogCategory, const std::string &message) {
            messages.push_back(message);
        });
        {
            auto logging_backend = std::make_unique<ControlledTunnel>();
            auto *backend = logging_backend.get();
            backend->fail_fetch = true;
            auto journal = std::make_unique<MemoryProfileJournal>();
            auto *pending = journal.get();
            AppSession logged(std::make_unique<FileProfileRepository>(root / "logging"), importer,
                std::make_unique<Partout::Tunnel>(std::move(logging_backend)), logger, std::move(journal), std::chrono::milliseconds(0));
            Wait(logged);
            const auto count = messages.size();
            logged.Refresh();
            Wait(logged);
            assert(messages.size() == count);
            backend->fail_fetch = false;
            backend->fake.Save(Example("orphan"));
            pending->Save({"orphan", std::nullopt, true});
            backend->fail_remove = true;
            logged.Refresh();
            Wait(logged);
            assert(logged.Snapshot().tunnel_available);
            assert(logged.Snapshot().tunnel_error.empty());
            assert(!logged.Snapshot().reconciliation_error.empty());
            backend->fail_remove = false;
            logged.Refresh();
            Wait(logged);
            assert(logged.Snapshot().reconciliation_error.empty());
        }
        const auto contains_log = [&](const std::string &part) {
            return std::any_of(messages.begin(), messages.end(), [&](const auto &message) { return message.find(part) != std::string::npos; });
        };
        assert(contains_log("Reload local profiles"));
        assert(contains_log("Unable to fetch tunnel state"));
        assert(contains_log("Tunnel observation recovered"));
        assert(contains_log("Unable to recover profile orphan"));
        assert(contains_log("Profile reconciliation recovered"));
        assert(contains_log("Finished application session"));

        auto failed = std::make_unique<ControlledTunnel>();
        auto *session_strategy = failed.get();
        failed->fail_connect = true;
        AppSession session(std::make_unique<FileProfileRepository>(root / "profiles"), importer, std::make_unique<Partout::Tunnel>(std::move(failed)));
        Wait(session);
        assert(session.Snapshot().loaded);
        assert(session.Snapshot().profiles.size() == 2);
        assert(session.Snapshot().profiles.at(0).primaryModuleType->value == Partout::Models::ModuleType::Provider);
        session.Connect(p.id);
        Wait(session);
        assert(!session.Snapshot().error.empty());
        assert(session.Snapshot().error_context == Passepartout::AppErrorContext::tunnel);
        assert(session.Snapshot().tunnels.at(0).status.value == Status::disconnected);
        session.ClearError();
        // Failed files do not prevent the rest of a batch being processed.
        const auto another = root / "another.conf";
        std::ofstream(another) << "another configuration";
        {
            auto backend = std::make_unique<ControlledTunnel>();
            auto *registration = backend.get();
            AppSession imported(std::make_unique<FileProfileRepository>(root / "registration"), importer, std::make_unique<Partout::Tunnel>(std::move(backend)));
            Wait(imported);
            // An import cannot overwrite or roll back an existing native registration.
            registration->fake.Save(Example("imported"));
            registration->fake.Connect("imported");
            imported.Import({config});
            Wait(imported);
            assert(!imported.Snapshot().error.empty());
            assert(imported.Snapshot().profiles.empty());
            assert(registration->events.empty() && registration->removal_attempts == 0);
            assert(registration->fake.Fetch().front().status.value == Partout::Models::TunnelStatus::active);
            registration->fake.Remove("imported");
            imported.Import({config});
            Wait(imported);
            assert(imported.Snapshot().error.empty());
            assert(registration->events == std::vector<std::string>{"save:imported"});
            assert(imported.Snapshot().tunnels.at(0).status.value == Status::disconnected);
            imported.Connect("imported");
            Wait(imported);
            assert((registration->events == std::vector<std::string>{"save:imported", "connect:imported"}));
            registration->fail_save = true;
            imported.Import({another});
            Wait(imported);
            assert(!imported.Snapshot().error.empty());
            assert(imported.Snapshot().error_context == Passepartout::AppErrorContext::import);
            assert(FileProfileRepository(root / "registration").Fetch().size() == 1);
            assert(imported.Snapshot().profiles.size() == 1);
            registration->fail_save = false;
            imported.Import({another});
            Wait(imported);
            assert(imported.Snapshot().error.empty());
            assert(imported.Snapshot().tunnels.size() == 2);
            assert(std::count(registration->events.begin(), registration->events.end(), "save:imported") == 1);
            assert(std::count(registration->events.begin(), registration->events.end(), "save:batch-id") == 2);
        }
        // Import requires native registration; failed observation must not save locally.
        auto unavailable = std::make_unique<ControlledTunnel>();
        auto *unavailable_strategy = unavailable.get();
        unavailable->fail_fetch = true;
        AppSession offline(std::make_unique<FileProfileRepository>(root / "offline"), importer, std::make_unique<Partout::Tunnel>(std::move(unavailable)),
            std::make_shared<AppLogger>(), std::make_unique<MemoryProfileJournal>(), std::chrono::milliseconds(0));
        Wait(offline);
        // A transient startup observation failure is not a failed user action.
        assert(offline.Snapshot().loaded);
        assert(offline.Snapshot().error.empty());
        assert(!offline.Snapshot().tunnel_error.empty());
        assert(!offline.Snapshot().tunnel_available);
        unavailable_strategy->fail_fetch = false;
        offline.Refresh();
        Wait(offline);
        assert(offline.Snapshot().error.empty());
        assert(offline.Snapshot().tunnel_error.empty());
        assert(offline.Snapshot().tunnel_available);
        unavailable_strategy->fail_fetch = true;
        offline.Import({another});
        Wait(offline);
        assert(!offline.Snapshot().error.empty());
        assert(!offline.Snapshot().tunnel_error.empty());
        assert(!offline.Snapshot().tunnel_available);
        assert(offline.Snapshot().profiles.empty());
        assert(FileProfileRepository(root / "offline").Fetch().empty());
        unavailable_strategy->fail_fetch = false;
        offline.Import({another});
        Wait(offline);
        assert(offline.Snapshot().error.empty());
        assert(offline.Snapshot().profiles.size() == 1);
        unavailable_strategy->fail_fetch = true;
        offline.Import({root / "missing.conf"});
        Wait(offline);
        assert(!offline.Snapshot().error.empty());
        assert(offline.Snapshot().error_context == Passepartout::AppErrorContext::import);
        offline.Remove({"batch-id"});
        Wait(offline);
        assert(offline.Snapshot().error.empty());
        assert(offline.Snapshot().profiles.empty());
        assert(FileProfileRepository(root / "offline").Fetch().empty());
        // A registration left during an outage is reconciled on recovery.
        unavailable_strategy->fake.Save(Example("batch-id"));
        offline.ClearError();
        unavailable_strategy->fail_fetch = false;
        offline.Refresh();
        Wait(offline);
        assert(offline.Snapshot().tunnel_error.empty());
        assert(offline.Snapshot().tunnel_available);
        assert(offline.Snapshot().tunnels.empty());
        // Startup also reconciles registrations left by a previous process.
        auto orphaned = std::make_unique<ControlledTunnel>();
        orphaned->fake.Save(Example("orphaned"));
        AppSession restarted(std::make_unique<FileProfileRepository>(root / "offline"), importer, std::make_unique<Partout::Tunnel>(std::move(orphaned)));
        Wait(restarted);
        // An untracked registration is not proof of an interrupted deletion.
        assert(restarted.Snapshot().tunnels.size() == 1);
        // Failed local loading is not evidence that all profiles were deleted.
        auto corrupt_repository = std::make_unique<FileProfileRepository>(root / "corrupt");
        std::ofstream(root / "corrupt" / "objects" / "broken.json") << "invalid";
        auto retained = std::make_unique<ControlledTunnel>();
        retained->fake.Save(Example("retained"));
        AppSession corrupt(std::move(corrupt_repository), importer, std::make_unique<Partout::Tunnel>(std::move(retained)));
        Wait(corrupt);
        assert(!corrupt.Snapshot().loaded);
        assert(!corrupt.Snapshot().error.empty());
        assert(corrupt.Snapshot().tunnels.size() == 1);
        session.Import({root / "missing.conf", another});
        Wait(session);
        assert(!session.Snapshot().error.empty());
        assert(session.Snapshot().error_context == Passepartout::AppErrorContext::import);
        assert(session.Snapshot().profiles.size() == 3);
        session.Remove({"imported", "batch-id"});
        Wait(session);
        assert(session.Snapshot().profiles.size() == 1);
        FileProfileRepository reopened(root / "profiles");
        assert(reopened.Fetch().size() == 1);
        assert(reopened.Fetch().at(0).id == p.id);

        // Row toggles use observed state and reject unavailable or busy actions.
        session_strategy->fake.Save(Example("broken-orphan"));
        session_strategy->observation_errors.emplace("broken-orphan", "Invalid handle");
        session_strategy->observation_errors.emplace(p.id, "Invalid handle");
        session.Refresh();
        Wait(session);
        assert(session.Snapshot().tunnel_available);
        assert(session.Snapshot().tunnel_error.empty());
        assert(session.Snapshot().reconciliation_error.empty());
        assert(session.Snapshot().tunnel_observation_errors.size() == 2);
        assert(!TunnelObservable::StateForProfile(session.Snapshot(), p.id).can_interact);
        session_strategy->observation_errors.erase(p.id);
        session.Refresh();
        Wait(session);
        assert(TunnelObservable::StateForProfile(session.Snapshot(), p.id).can_interact);
        assert(session.Snapshot().tunnel_observation_errors.size() == 1);
        const auto retained_registrations = session_strategy->fake.Fetch();
        assert(std::any_of(retained_registrations.begin(), retained_registrations.end(), [](const auto &info) {
            return info.id == "broken-orphan";
        }));
        TunnelObservable toggle(session);
        session_strategy->fail_connect = false;
        toggle.SetEnabled(p.id, true);
        Wait(session);
        auto toggle_state = TunnelObservable::StateForProfile(session.Snapshot(), p.id);
        assert(toggle_state.is_on && toggle_state.can_interact);
        toggle.SetEnabled(p.id, false);
        Wait(session);
        toggle_state = TunnelObservable::StateForProfile(session.Snapshot(), p.id);
        assert(!toggle_state.is_on && toggle_state.can_interact);
        auto unavailable_state = session.Snapshot();
        unavailable_state.tunnel_available = false;
        assert(!TunnelObservable::StateForProfile(unavailable_state, p.id).can_interact);
        unavailable_state = session.Snapshot();
        unavailable_state.tunnel_observation_errors.emplace(p.id, "Invalid handle");
        assert(!TunnelObservable::StateForProfile(unavailable_state, p.id).can_interact);
        unavailable_state.tunnel_observation_errors.clear();
        unavailable_state.tunnel_observation_errors.emplace("broken-orphan", "Invalid handle");
        assert(TunnelObservable::StateForProfile(unavailable_state, p.id).can_interact);
        unavailable_state = session.Snapshot();
        unavailable_state.foreground_busy = true;
        assert(!TunnelObservable::StateForProfile(unavailable_state, p.id).can_interact);
        assert(!TunnelObservable::StateForProfile(session.Snapshot(), "missing").can_interact);
        auto transitioning = session.Snapshot();
        transitioning.tunnels.at(0).status.value = Status::connecting;
        transitioning.tunnels.at(0).isEnabled = true;
        assert(TunnelObservable::StateForProfile(transitioning, p.id).can_interact);
        transitioning.tunnels.at(0).status.value = Status::disconnecting;
        assert(!TunnelObservable::StateForProfile(transitioning, p.id).can_interact);
        transitioning.tunnels.at(0).id = "another-active-profile";
        assert(TunnelObservable::StateForProfile(transitioning, p.id).can_interact);
        session_strategy->fail_connect = true;
        toggle.SetEnabled(p.id, true);
        Wait(session);
        assert(!session.Snapshot().error.empty());
        assert(!TunnelObservable::StateForProfile(session.Snapshot(), p.id).is_on);
        session.ClearError();
        session_strategy->fail_connect = false;

        auto gate = std::make_shared<Gate>();
        auto entered = gate->entered.get_future();
        AppSession queued(std::make_unique<FileProfileRepository>(root / "profiles"),
                          importer, std::make_unique<Partout::Tunnel>(std::make_unique<BlockingTunnel>(gate)));
        Wait(queued);
        queued.Connect(p.id);
        assert(entered.wait_for(std::chrono::seconds(5)) == std::future_status::ready);
        queued.Disconnect(p.id);
        assert(queued.Snapshot().busy);
        assert(!TunnelObservable::StateForProfile(queued.Snapshot(), p.id).can_interact);
        gate->release.set_value();
        Wait(queued);
        assert(queued.Snapshot().error.empty());
        assert(queued.Snapshot().tunnels.at(0).status.value == Status::disconnected);

        auto delayed = std::make_unique<ControlledTunnel>();
        delayed->fake.Save(p);
        delayed->fake.Connect(p.id);
        delayed->delayed_disconnect = true;
        auto *delayed_strategy = delayed.get();
        AppSession removal(std::make_unique<FileProfileRepository>(root / "profiles"),
            importer, std::make_unique<Partout::Tunnel>(std::move(delayed)), std::make_shared<AppLogger>(),
            std::make_unique<MemoryProfileJournal>(), std::chrono::milliseconds(0));
        Wait(removal);
        removal.Remove({p.id});
        Wait(removal);
        assert(removal.Snapshot().error.empty());
        assert(removal.Snapshot().tunnel_error.empty());
        assert(removal.Snapshot().tunnel_available);
        assert(!removal.Snapshot().reconciliation_error.empty());
        assert(removal.Snapshot().profiles.empty());
        assert(reopened.Fetch().empty());
        // Keep the Windows registration until disconnect actually finishes.
        assert(delayed_strategy->fake.Fetch().size() == 1);
        delayed_strategy->fake.SetStatus(p.id, Partout::Models::TunnelStatus::inactive);
        removal.Refresh();
        Wait(removal);
        assert(removal.Snapshot().tunnel_error.empty());
        assert(removal.Snapshot().tunnels.empty());
        assert(removal.Snapshot().reconciliation_error.empty());
    } catch (...) {
        std::filesystem::remove_all(root);
        try {
            throw;
        } catch (const std::exception &error) {
            std::cerr << "Application test failed: " << error.what() << std::endl;
        } catch (...) {
            std::cerr << "Application test failed with an unknown exception." << std::endl;
        }
        return 1;
    }
    std::filesystem::remove_all(root);
    std::cout << "Persistence, import, reconciliation and failure-state checks passed.\n";
}
