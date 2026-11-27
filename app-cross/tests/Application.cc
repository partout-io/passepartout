// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "MainThreadQueue.h"
#include "ScopedLogSink.h"
#include "business/strategy/ConfigurationFiles.h"
#include "business/managers/ProfileManager.h"
#include "business/strategy/FileProfileRepository.h"
#include "business/extensions/Models+Business.h"
#include "context/ContextExtensions.h"
#include <atomic>
#include <partout/tunnel/Tunnel.h>
#include "business/strategy/FakeTunnelStrategy.h"
#include "ObservableFixture.h"
#include "observables/ProfileObservable.h"
#include "observables/TunnelObservable.h"
#include "ui/platform/ModalConfigurationPicker.h"
#include "ui/extensions/Models+UI.h"
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
    bool lose_observation_on_disconnect = false;
    unsigned removal_attempts = 0;
    std::map<std::string, std::string> observation_errors;
    std::vector<std::string> events;
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
void Wait(Passepartout::Tests::ObservableFixture &session) {
    do {
        assert(session.executor.WaitIdle(std::chrono::seconds(5)));
        Passepartout::Tests::MainThreadQueue::Drain();
    } while (session.executor.CurrentActivity().busy);
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
        : cancellation_(std::move(cancellation)) {}

    std::size_t Count() const override {
        return 1;
    }

    std::size_t SelectionFailures() const override {
        return 0;
    }

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
        Passepartout::Tests::ObservableFixture session(std::make_unique<Passepartout::FileProfileRepository>(root / "cancel-tunnel"), {},
            std::make_unique<Partout::Tunnel>(std::make_unique<CancelableTunnel>(tunnel)));
        tunnel->WaitForEntry();
    }
    assert(tunnel->canceled);
    const auto files = std::make_shared<Cancellation>();
    {
        Passepartout::Tests::ObservableFixture session(std::make_unique<Passepartout::FileProfileRepository>(root / "cancel-files"), {},
            std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>()));
        Wait(session);
        session.profiles.ImportFiles(std::make_shared<CancelableFiles>(files));
        files->WaitForEntry();
    }
    assert(files->canceled);
}

void TestObservableOrdering(const std::filesystem::path &root) {
    auto strategy = std::make_unique<ControlledTunnel>();
    auto *backend = strategy.get();
    Passepartout::Tests::ObservableFixture context(
        std::make_unique<Passepartout::FileProfileRepository>(root / "observable-ordering"),
        [](const std::string &, const std::string &) {
            return Example("queued-import");
        },
        std::make_unique<Partout::Tunnel>(std::move(strategy))
    );
    Wait(context);
    auto gate = std::make_shared<Gate>();
    auto entered = gate->entered.get_future();
    context.executor.Post([gate] {
        gate->entered.set_value();
        gate->release.get_future().wait();
    });
    assert(entered.wait_for(std::chrono::seconds(5)) == std::future_status::ready);
    context.profiles.ImportFiles(std::make_shared<Passepartout::MemoryConfigurationFiles>(
        std::vector<Passepartout::ConfigurationSource>{{"queued", "configuration"}}
    ));
    assert(context.profiles.Snapshot().busy);
    assert(!context.tunnel.Snapshot().busy);
    context.tunnel.Connect(Example("queued-import"));
    assert(context.tunnel.Snapshot().busy);
    assert(context.executor.CurrentActivity().foreground);
    gate->release.set_value();
    Wait(context);
    assert(!context.profiles.Snapshot().busy && !context.tunnel.Snapshot().busy);
    assert(!context.profiles.Snapshot().operation_error.has_value());
    assert(context.profiles.Snapshot().profiles.size() == 1);
    assert(context.tunnel.Snapshot().tunnels.front().status.value == Passepartout::Status::connected);
    assert((backend->events == std::vector<std::string>{"save:queued-import", "connect:queued-import"}));
}

void TestIndependentObservableState(const std::filesystem::path &root) {
    Passepartout::Tests::ObservableFixture context(
        std::make_unique<Passepartout::FileProfileRepository>(root / "independent-state"), {},
        std::make_unique<Partout::Tunnel>(std::make_unique<ControlledTunnel>())
    );
    Wait(context);
    context.profiles.ImportFailed();
    context.tunnel.Cancel();
    context.tunnel.Connect(Example("missing"));
    Wait(context);
    assert(context.profiles.Snapshot().operation_error.has_value());
    assert(context.tunnel.Snapshot().errors.operation);
    context.profiles.ClearOperationError();
    assert(!context.profiles.Snapshot().operation_error.has_value());
    assert(context.tunnel.Snapshot().errors.operation);
    context.tunnel.ClearOperationError();
    assert(!context.tunnel.Snapshot().errors.operation);
}

void TestMainThreadDelivery() {
    using Passepartout::MainThread;
    using Passepartout::Worker;
    std::vector<int> delivered;
    {
        MainThread owner;
        Worker worker;
        worker.Post([&] {
            owner.Post([&] { delivered.push_back(1); });
            owner.Post([&] { delivered.push_back(2); });
        });
        assert(worker.WaitIdle(std::chrono::seconds(5)));
        assert(delivered.empty());
        Passepartout::Tests::MainThreadQueue::Drain();
        assert((delivered == std::vector<int>{1, 2}));
        worker.Post([&] { owner.Post([&] { delivered.push_back(3); }); });
        assert(worker.WaitIdle(std::chrono::seconds(5)));
    }
    // Destruction invalidates already queued completions.
    Passepartout::Tests::MainThreadQueue::Drain();
    assert((delivered == std::vector<int>{1, 2}));
}

void TestStateNotifications(const std::filesystem::path &root) {
    Passepartout::Tests::ObservableFixture context(
        std::make_unique<Passepartout::FileProfileRepository>(root / "state-notifications"), {},
        std::make_unique<Partout::Tunnel>(std::make_unique<ControlledTunnel>())
    );
    Wait(context);
    std::mutex delivery_mutex;
    std::vector<std::thread::id> deliveries;
    const auto enqueue = [&] {
        context.profiles.Snapshot();
        context.tunnel.Snapshot();
        std::lock_guard lock(delivery_mutex);
        deliveries.push_back(std::this_thread::get_id());
    };
    const auto profile_subscription = context.profiles.changes.Subscribe(enqueue);
    const auto tunnel_subscription = context.tunnel.changes.Subscribe(enqueue);
    std::atomic<std::size_t> other_deliveries{0};
    const auto other_subscription = context.profiles.changes.Subscribe([&] { ++other_deliveries; });
    context.profiles.ImportFailed();
    assert(other_deliveries > 0);
    context.tunnel.Connect(Example("notification"));
    Wait(context);
    // Every publication is delivered on the owning main thread.
    {
        std::lock_guard lock(delivery_mutex);
        assert(std::all_of(deliveries.begin(), deliveries.end(), [](auto thread) {
            return thread == std::this_thread::get_id();
        }));
    }
    // The consumer reads the latest state on its own thread, without a timer.
    assert(context.profiles.Snapshot().operation_error);
    assert(!context.tunnel.Snapshot().tunnels.empty());
    context.profiles.changes.Unsubscribe(profile_subscription);
    context.tunnel.changes.Unsubscribe(tunnel_subscription);
    const auto count = deliveries.size();
    context.profiles.ClearOperationError();
    context.tunnel.Disconnect("notification");
    Wait(context);
    assert(deliveries.size() == count);
    const auto other_count = other_deliveries.load();
    assert(other_count > 1); // Unsubscribing one view leaves the other subscribed.
    context.profiles.changes.Unsubscribe(other_subscription);
    context.profiles.ImportFailed();
    assert(other_deliveries == other_count);
}

void TestObservationAfterOperationFailure(const std::filesystem::path &root) {
    auto repository = std::make_unique<Passepartout::FileProfileRepository>(root / "observe-after-failure");
    repository->Save(Example());
    auto strategy = std::make_unique<ControlledTunnel>();
    auto *backend = strategy.get();
    Passepartout::Tests::ObservableFixture context(
        std::move(repository), {}, std::make_unique<Partout::Tunnel>(std::move(strategy))
    );
    Wait(context);
    backend->fail_connect = true;
    context.tunnel.Connect(Example("test-id"));
    Wait(context);
    const auto operation_error = context.tunnel.Snapshot().errors.operation;
    assert(operation_error);
    backend->fail_fetch = true;
    context.tunnel.Refresh();
    Wait(context);
    assert(!context.tunnel.Snapshot().available);
    assert(context.tunnel.Snapshot().errors.operation == operation_error);
    backend->fail_fetch = false;
    backend->fake.Connect("test-id");
    context.tunnel.Refresh();
    Wait(context);
    const auto state = context.tunnel.Snapshot();
    assert(state.available);
    assert(state.errors.operation == operation_error);
    assert(state.tunnels.front().status.value == Passepartout::Status::connected);
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
    Passepartout::Tests::ObservableFixture session(
        std::move(repository), {}, std::make_unique<Partout::Tunnel>(std::move(strategy))
    );
    Wait(session);
    backend->fake.Save(Example("first"));
    backend->fake.Connect("first");
    session.tunnel.Connect(Example("second"));
    Wait(session);
    assert(session.tunnel.Snapshot().pending_profile == "second");
    session.tunnel.Refresh();
    Wait(session);
    assert(session.tunnel.Snapshot().pending_profile == "second");
    backend->fake.Disconnect("first");
    session.tunnel.Refresh();
    Wait(session);
    assert(session.tunnel.Snapshot().pending_profile == "second");
    backend->fake.Connect("second");
    session.tunnel.Refresh();
    Wait(session);
    assert(!session.tunnel.Snapshot().pending_profile);

    // Failed activation clears the UI request and retains the tunnel error context.
    backend->delayed_disconnect = false;
    session.tunnel.Connect(Example("first"));
    Wait(session);
    assert(session.tunnel.Snapshot().pending_profile == "first");
    backend->fake.Disconnect("first");
    session.tunnel.Refresh();
    Wait(session);
    assert(!session.tunnel.Snapshot().pending_profile);
    assert(session.tunnel.Snapshot().errors.operation);

    session.tunnel.Connect(Example("second"));
    Wait(session);
    assert(session.tunnel.Snapshot().pending_profile == "second");
    session.tunnel.Disconnect("second");
    Wait(session);
    assert(!session.tunnel.Snapshot().pending_profile && !session.tunnel.Snapshot().errors.operation);
    session.tunnel.Connect(Example("second"));
    Wait(session);
    session.profiles.Remove({"second"});
    Wait(session);
    assert(!session.tunnel.Snapshot().pending_profile && !session.tunnel.Snapshot().errors.operation);
    session.tunnel.Refresh();
    Wait(session);
    assert(session.tunnel.Snapshot().tunnels.size() == 1);
    assert(session.tunnel.Snapshot().tunnels.front().id == "first");
}

void TestProfileEvents(const std::filesystem::path &root) {
    auto repository = std::make_unique<Passepartout::FileProfileRepository>(root / "profile-events");
    const auto original = Example("event-profile");
    repository->Save(original);
    auto backend = std::make_unique<ControlledTunnel>();
    auto *native = backend.get();
    Passepartout::Tests::ObservableFixture session(
        std::move(repository), {}, std::make_unique<Partout::Tunnel>(std::move(backend))
    );
    Wait(session);
    session.tunnel.Connect(original);
    Wait(session);
    const auto operations = native->events;
    auto edited = original;
    edited.name = "Edited";
    session.executor.Post([&] { session.profile_manager.Update(original, edited); });
    Wait(session);
    assert(session.profiles.FindProfile(original.id)->name == edited.name);
    assert(native->events == operations);
    assert(session.tunnel.Snapshot().tunnels.front().isEnabled);
    // Delete through the manager, bypassing ProfileObservable entirely.
    session.executor.Post([&] { session.profile_manager.Remove(original.id); });
    Wait(session);
    assert(session.tunnel.Snapshot().tunnels.empty());
    assert(session.profile_manager.Profiles().empty());
    assert(session.profiles.Snapshot().profiles.empty());
    assert(!session.profiles.FindProfile(original.id));
    // A manager reload also refreshes the observable without its Load action.
    Passepartout::FileProfileRepository(root / "profile-events").Save(original);
    session.executor.Post([&] { session.profile_manager.Load(); });
    Wait(session);
    assert(session.profiles.Snapshot().loaded);
    assert(session.profiles.FindProfile(original.id) == original);

    auto failing = std::make_unique<FailingImportRepository>();
    failing->stored = {original};
    failing->fail_remove = true;
    auto *storage = failing.get();
    Passepartout::ProfileManager manager(std::move(failing), {});
    manager.Load();
    std::vector<Passepartout::Models::Event> events;
    const auto subscription = manager.events.Subscribe([&](const auto &event) { events.push_back(event); });
    Rejects([&] { manager.Remove(original.id); });
    assert(events.empty());
    storage->fail_remove = false;
    manager.Remove(original.id);
    assert(events.size() == 1);
    assert(std::get<Passepartout::Models::ProfileEventDelete>(events.front()).ids ==
        std::vector<std::string>{original.id});
    manager.events.Unsubscribe(subscription);
    storage->stored = {original};
    manager.Load();
    manager.Remove(original.id);
    assert(events.size() == 1);
}

void TestRemovalTargets(const std::filesystem::path &root) {
    const auto directory = root / "removal-targets";
    auto repository = std::make_unique<Passepartout::FileProfileRepository>(directory);
    repository->Save(Example("first"));
    repository->Save(Example("second"));
    Passepartout::Tests::ObservableFixture session(std::move(repository), {}, std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>()));
    auto &profiles = session.profiles;
    Wait(session);
    const std::vector<std::string> targets{"first", "second"};
    auto state = profiles.Snapshot();
    assert(Passepartout::ProfileObservable::CanRemove(state, targets));
    assert(!Passepartout::ProfileObservable::CanRemove(state, {}));
    assert(!Passepartout::ProfileObservable::CanRemove(state, {"missing"}));
    state.busy = true;
    assert(!Passepartout::ProfileObservable::CanRemove(state, targets));
    state.busy = false;
    state.loaded = false;
    assert(!Passepartout::ProfileObservable::CanRemove(state, targets));

    // A stale target invalidates the whole batch before any local mutation.
    session.profiles.Remove({"first", "missing"});
    Wait(session);
    assert(profiles.Snapshot().operation_error.has_value());
    assert(Passepartout::FileProfileRepository(directory).Fetch().size() == 2);
    profiles.ClearOperationError();
    profiles.Remove({"first", "first"});
    Wait(session);
    assert(!profiles.Snapshot().operation_error.has_value());
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
        if (cancel) active->Cancel();
        if (dismiss) return {};
        return {std::make_shared<Passepartout::FileConfigurationFiles>(
            std::vector<std::filesystem::path>{"selected.conf"}), false};
    });
    active = &picker;
    picker.Start();
    auto result = picker.Poll();
    assert(result && result->files && result->files->Count() == 1);
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
    auto selected = Passepartout::CollectConfigurationFiles(5, [&](std::size_t index) {
        visited.push_back(index);
        if (index == 1) return valid;
        if (index == 3) return invalid;
        throw std::runtime_error("Native staging failed");
    });
    assert(visited.size() == 5);
    assert(selected.paths.size() == 2 && selected.SelectionFailures() == 3);
    Passepartout::Tests::ObservableFixture session(std::make_unique<Passepartout::FileProfileRepository>(root / "selection-store"),
        [](const std::string &text, const std::string &) {
            if (text != "valid") throw std::runtime_error("Invalid configuration");
            return Example("selected-valid");
        }, std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>()));
    Wait(session);
    session.profiles.ImportFiles(std::make_shared<Passepartout::FileConfigurationFiles>(std::move(selected)));
    Wait(session);
    auto snapshot = session.profiles.Snapshot();
    assert(snapshot.profiles.size() == 1 && snapshot.profiles.front().id == "selected-valid");
    assert(snapshot.operation_error == Passepartout::ProfileObservable::OperationErrorContext::import);
    assert(Passepartout::FileProfileRepository(root / "selection-store").Fetch().size() == 1);

    auto failed = Passepartout::CollectConfigurationFiles(2, [](std::size_t) -> std::filesystem::path {
        throw std::runtime_error("Unreadable file");
    });
    session.profiles.ImportFiles(std::make_shared<Passepartout::FileConfigurationFiles>(std::move(failed)));
    Wait(session);
    assert(session.profiles.Snapshot().operation_error == Passepartout::ProfileObservable::OperationErrorContext::import);
    assert(session.profiles.Snapshot().profiles.size() == 1);
    auto empty = Passepartout::CollectConfigurationFiles(0, [](std::size_t) -> std::filesystem::path {
        assert(false);
        return {};
    });
    std::atomic<int> notifications{0};
    const auto subscription = session.profiles.changes.Subscribe([&] { ++notifications; });
    session.profiles.ImportFiles(std::make_shared<Passepartout::FileConfigurationFiles>(std::move(empty)));
    session.profiles.changes.Unsubscribe(subscription);
    assert(notifications == 0);
}

void TestLargeSelection(const std::filesystem::path &root) {
    constexpr std::size_t count = 40;
    auto selected = Passepartout::CollectConfigurationFiles(count, [&](std::size_t index) {
        const auto path = root / ("batch-" + std::to_string(index) + ".conf");
        std::ofstream(path) << "batch-" << index;
        return path;
    });
    assert(selected.paths.size() == count && selected.SelectionFailures() == 0);
    Passepartout::Tests::ObservableFixture session(std::make_unique<Passepartout::FileProfileRepository>(root / "large-selection-store"),
        [](const std::string &text, const std::string &) {
            return Example(text);
        }, std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>()));
    Wait(session);
    session.profiles.ImportFiles(std::make_shared<Passepartout::FileConfigurationFiles>(std::move(selected)));
    Wait(session);
    const auto snapshot = session.profiles.Snapshot();
    assert(!snapshot.operation_error.has_value());
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
        : files_({path}), destroyed_(std::move(destroyed)) {}

    ~TemporaryConfigurationFiles() override {
        std::error_code error;
        std::filesystem::remove(files_.paths.front(), error);
        destroyed_->set_value();
    }

    std::size_t Count() const override {
        return files_.Count();
    }

    std::size_t SelectionFailures() const override {
        return files_.SelectionFailures();
    }

    Passepartout::ConfigurationSource Read(std::size_t index) const override {
        return files_.Read(index);
    }

    void Cancel() const noexcept override {
        files_.Cancel();
    }
private:
    Passepartout::FileConfigurationFiles files_;
    std::shared_ptr<std::promise<void>> destroyed_;
};
void TestSelectedFiles(const std::filesystem::path &root, bool fail) {
    const auto input = root / "selected.conf";
    std::ofstream(input) << "selected configuration";
    auto gate = std::make_shared<Gate>();
    auto entered = gate->entered.get_future();
    auto destroyed = std::make_shared<std::promise<void>>();
    auto cleanup = destroyed->get_future();
    Passepartout::Tests::ObservableFixture session(std::make_unique<Passepartout::FileProfileRepository>(root / "store"),
        [gate, fail](const std::string &text, const std::string &name) {
            assert(text == "selected configuration");
            assert(name == "selected");
            gate->entered.set_value();
            gate->release.get_future().wait();
            if (fail) throw std::runtime_error("Invalid configuration");
            return Example();
        }, std::make_unique<Partout::Tunnel>(std::make_unique<Passepartout::FakeTunnelStrategy>()));
    Wait(session);
    auto &observable = session.profiles;
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
    assert(session.profiles.Snapshot().operation_error.has_value() == fail);
    assert(session.profiles.Snapshot().profiles.size() == (fail ? 0 : 1));
    observable.ClearOperationError();
    std::atomic<int> notifications{0};
    const auto subscription = observable.changes.Subscribe([&] { ++notifications; });
    observable.ImportFiles(nullptr);
    observable.ImportFiles(std::make_shared<Passepartout::FileConfigurationFiles>(std::vector<std::filesystem::path>{}));
    observable.changes.Unsubscribe(subscription);
    assert(notifications == 0);
    observable.ImportFailed();
    Wait(session);
    assert(observable.Snapshot().operation_error.has_value());
    assert(observable.Snapshot().operation_error == Passepartout::ProfileObservable::OperationErrorContext::import);
}
}

using namespace Passepartout;
int main() {
    Passepartout::Tests::MainThreadQueue main_thread;
#ifdef _MSC_VER
    _set_error_mode(_OUT_TO_STDERR);
    _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
#endif
    TestMainThreadDelivery();
    TestModalPicker();
    TestRemovalObservation();
    {
        auto strategy = std::make_unique<ControlledTunnel>();
        auto *control = strategy.get();
        control->fake.Save(Example("broken"));
        control->observation_errors.emplace("broken", "Invalid handle");
        Partout::Tunnel manager(std::move(strategy));
        manager.Connect(Example("healthy"));
        assert((control->events == std::vector<std::string>{"save:healthy", "connect:healthy"}));
        assert(manager.Fetch().at(0).status.value == Partout::Models::TunnelStatus::active);
        assert(manager.ObservationErrors().count("broken") == 1);
        Rejects([&] { manager.Connect(Example("broken")); });
        assert(control->events.size() == 2);
    }
    auto constants = Constants::Load();
    assert(constants.containers.local == "Local");
    assert(Profiles::Directory("root", constants) == std::filesystem::path("root/local"));
    constants.containers.local = "Testing";
    assert(Profiles::Directory("root", constants) == std::filesystem::path("root/testing"));
    constants.containers.local = "../outside";
    Rejects([&] { Profiles::Directory("root", constants); });
    const auto imported = ImportProfile(
        "[Interface]\n"
        "PrivateKey = 4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw=\n"
        "Address = 10.0.0.2/32\n"
        "[Peer]\n"
        "PublicKey = muwialz9E36nXp9qgbGIxwMrH+5Ovr8d7cutH8JHdvE=\n"
        "AllowedIPs = 0.0.0.0/0\n"
        "Endpoint = wg.example.com:51820\n",
        "Imported WireGuard"
    );
    assert(imported.name == "Imported WireGuard");
    assert(!imported.modules.empty());
    for (const auto *invalid : {"", "not a configuration", "{}"}) {
        try {
            ImportProfile(invalid, "Invalid");
            assert(false);
        } catch (const std::runtime_error &error) {
            assert(std::string(error.what()) == "Partout could not import this configuration.");
        }
    }
    const auto root = std::filesystem::temp_directory_path() /
        ("passepartout-test-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    std::filesystem::create_directories(root);
    try {
        TestProfileEvents(root);
        TestRemovalTargets(root);
        TestPendingActivation(root);
        TestShutdown(root);
        TestObservableOrdering(root);
        TestIndependentObservableState(root);
        TestStateNotifications(root);
        TestObservationAfterOperationFailure(root);
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
            ProfileManager manager(std::move(repository), importer);
            manager.Load();
            Rejects([&] { manager.Import(config); });
            assert(manager.Profiles().empty());
            // A partial storage write remains authoritative when reloaded; no native rollback is involved.
            assert(storage->stored.size() == 1);
            manager.Load();
            assert(manager.Profiles().size() == 1);
        }

        auto controlled = std::make_unique<ControlledTunnel>();
        auto *strategy = controlled.get();
        Partout::Tunnel tunnel(std::move(controlled));
        tunnel.Connect(p);
        assert(tunnel.Fetch().at(0).status.value == Partout::Models::TunnelStatus::active);
        tunnel.Connect(Example("second"));
        assert(strategy->fake.Fetch().at(0).status.value == Partout::Models::TunnelStatus::inactive);
        assert(strategy->fake.Fetch().at(1).status.value == Partout::Models::TunnelStatus::active);
        assert((strategy->events == std::vector<std::string>{"save:" + p.id, "connect:" + p.id,
            "disconnect:" + p.id, "save:second", "connect:second"}));
        tunnel.Connect(p);
        tunnel.Remove("second");
        strategy->delayed_disconnect = true;
        tunnel.Remove(p.id);
        assert(tunnel.Fetch().size() == 1);
        strategy->fake.SetStatus(p.id, Partout::Models::TunnelStatus::inactive);
        tunnel.Advance();
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
        assert((handover_strategy->events == std::vector<std::string>{"disconnect:" + p.id, "save:latest", "connect:latest"}));
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
        TunnelObservable::State activity;
        activity.busy = true;
        assert(activity.HasActivity());
        activity.busy = false;
        activity.pending_profile = "next";
        assert(activity.HasActivity());
        activity.pending_profile.reset();
        Models::AppTunnelInfo transition{};
        transition.status.value = Status::connecting;
        activity.tunnels.push_back(transition);
        activity.available = true;
        assert(activity.HasActivity());
        activity.tunnels[0].status.value = Status::disconnecting;
        assert(activity.HasActivity());
        activity.tunnels[0].status.value = Status::connected;
        assert(!activity.HasActivity());

        auto failed = std::make_unique<ControlledTunnel>();
        auto *session_strategy = failed.get();
        failed->fail_connect = true;
        Tests::ObservableFixture session(std::make_unique<FileProfileRepository>(root / "profiles"), importer, std::make_unique<Partout::Tunnel>(std::move(failed)));
        Wait(session);
        assert(session.profiles.Snapshot().loaded);
        assert(session.profiles.Snapshot().profiles.size() == 2);
        assert(session.profiles.Snapshot().profiles.at(0).primaryModuleType->value == Partout::Models::ModuleType::Provider);
        session.tunnel.Connect(Example(p.id));
        Wait(session);
        assert(session.tunnel.Snapshot().errors.operation);
        assert(session.tunnel.Snapshot().tunnels.at(0).status.value == Status::disconnected);
        session.ClearOperationErrors();
        // Failed files do not prevent the rest of a batch being processed.
        const auto another = root / "another.conf";
        std::ofstream(another) << "another configuration";
        {
            auto backend = std::make_unique<ControlledTunnel>();
            auto *registration = backend.get();
            Tests::ObservableFixture imported(std::make_unique<FileProfileRepository>(root / "registration"), importer, std::make_unique<Partout::Tunnel>(std::move(backend)));
            Wait(imported);
            // Import persists independently of an active native registration.
            registration->fake.Save(Example("imported"));
            registration->fake.Connect("imported");
            imported.profiles.Import({config});
            Wait(imported);
            assert(!imported.profiles.Snapshot().operation_error.has_value());
            assert(imported.profiles.Snapshot().profiles.size() == 1);
            assert(registration->events.empty() && registration->removal_attempts == 0);
            assert(registration->fake.Fetch().front().status.value == Partout::Models::TunnelStatus::active);
            registration->fake.Remove("imported");
            imported.tunnel.Refresh();
            Wait(imported);
            assert(!imported.profiles.Snapshot().operation_error.has_value());
            assert(registration->events.empty());
            assert(imported.tunnel.Snapshot().tunnels.empty());
            imported.tunnel.Connect(Example("imported"));
            Wait(imported);
            assert((registration->events == std::vector<std::string>{"save:imported", "connect:imported"}));
            registration->fail_save = true;
            imported.profiles.Import({another});
            Wait(imported);
            assert(!imported.profiles.Snapshot().operation_error.has_value());
            imported.tunnel.Connect(Example("batch-id"));
            Wait(imported);
            assert(imported.tunnel.Snapshot().errors.operation);
            assert(FileProfileRepository(root / "registration").Fetch().size() == 2);
            assert(imported.profiles.Snapshot().profiles.size() == 2);
            registration->fail_save = false;
            imported.tunnel.Connect(Example("batch-id"));
            Wait(imported);
            assert(!imported.profiles.Snapshot().operation_error.has_value());
            assert(imported.tunnel.Snapshot().tunnels.size() == 2);
            assert(std::count(registration->events.begin(), registration->events.end(), "save:imported") == 1);
            assert(std::count(registration->events.begin(), registration->events.end(), "save:batch-id") == 2);
        }
        // Native observation failures must not prevent local imports.
        auto unavailable = std::make_unique<ControlledTunnel>();
        auto *unavailable_strategy = unavailable.get();
        unavailable->fail_fetch = true;
        Tests::ObservableFixture offline(std::make_unique<FileProfileRepository>(root / "offline"), importer, std::make_unique<Partout::Tunnel>(std::move(unavailable)));
        Wait(offline);
        // A transient startup observation failure is not a failed user action.
        assert(offline.profiles.Snapshot().loaded);
        assert(!offline.profiles.Snapshot().operation_error.has_value());
        assert(!offline.tunnel.Snapshot().available);
        unavailable_strategy->fail_fetch = false;
        offline.tunnel.Refresh();
        Wait(offline);
        assert(!offline.profiles.Snapshot().operation_error.has_value());
        assert(offline.tunnel.Snapshot().available);
        unavailable_strategy->fail_fetch = true;
        offline.profiles.Import({another});
        Wait(offline);
        offline.tunnel.Refresh();
        Wait(offline);
        assert(!offline.profiles.Snapshot().operation_error.has_value());
        assert(!offline.tunnel.Snapshot().available);
        assert(offline.profiles.Snapshot().profiles.size() == 1);
        assert(FileProfileRepository(root / "offline").Fetch().size() == 1);
        unavailable_strategy->fail_fetch = false;
        offline.tunnel.Refresh();
        Wait(offline);
        assert(!offline.profiles.Snapshot().operation_error.has_value());
        assert(offline.profiles.Snapshot().profiles.size() == 1);
        unavailable_strategy->fail_fetch = true;
        offline.profiles.Import({root / "missing.conf"});
        Wait(offline);
        assert(offline.profiles.Snapshot().operation_error.has_value());
        assert(offline.profiles.Snapshot().operation_error == Passepartout::ProfileObservable::OperationErrorContext::import);
        offline.profiles.Remove({"batch-id"});
        Wait(offline);
        assert(!offline.profiles.Snapshot().operation_error.has_value());
        assert(offline.profiles.Snapshot().profiles.empty());
        assert(FileProfileRepository(root / "offline").Fetch().empty());
        // Refresh observes registrations without reconciling them against local storage.
        unavailable_strategy->fake.Save(Example("batch-id"));
        offline.ClearOperationErrors();
        unavailable_strategy->fail_fetch = false;
        offline.tunnel.Refresh();
        Wait(offline);
        assert(offline.tunnel.Snapshot().available);
        assert(offline.tunnel.Snapshot().tunnels.size() == 1);
        // Startup observes registrations left by a previous process.
        auto orphaned = std::make_unique<ControlledTunnel>();
        orphaned->fake.Save(Example("orphaned"));
        Tests::ObservableFixture restarted(std::make_unique<FileProfileRepository>(root / "offline"), importer, std::make_unique<Partout::Tunnel>(std::move(orphaned)));
        Wait(restarted);
        // Loading stored profiles does not mutate native registrations.
        assert(restarted.tunnel.Snapshot().tunnels.size() == 1);
        // Failed local loading is not evidence that all profiles were deleted.
        auto corrupt_repository = std::make_unique<FileProfileRepository>(root / "corrupt");
        std::ofstream(root / "corrupt" / "objects" / "broken.json") << "invalid";
        auto retained = std::make_unique<ControlledTunnel>();
        retained->fake.Save(Example("retained"));
        Tests::ObservableFixture corrupt(std::move(corrupt_repository), importer, std::make_unique<Partout::Tunnel>(std::move(retained)));
        Wait(corrupt);
        assert(!corrupt.profiles.Snapshot().loaded);
        assert(corrupt.profiles.Snapshot().operation_error.has_value());
        assert(corrupt.tunnel.Snapshot().tunnels.size() == 1);
        session.profiles.Import({root / "missing.conf", another});
        Wait(session);
        assert(session.profiles.Snapshot().operation_error.has_value());
        assert(session.profiles.Snapshot().operation_error == Passepartout::ProfileObservable::OperationErrorContext::import);
        assert(session.profiles.Snapshot().profiles.size() == 3);
        session.profiles.Remove({"imported", "batch-id"});
        Wait(session);
        assert(session.profiles.Snapshot().profiles.size() == 1);
        FileProfileRepository reopened(root / "profiles");
        assert(reopened.Fetch().size() == 1);
        assert(reopened.Fetch().at(0).id == p.id);

        // Per-profile observation errors remain distinct from action failures.
        session_strategy->fake.Save(Example("broken-orphan"));
        session_strategy->observation_errors.emplace("broken-orphan", "Invalid handle");
        session_strategy->observation_errors.emplace(p.id, "Invalid handle");
        session.tunnel.Refresh();
        Wait(session);
        assert(session.tunnel.Snapshot().available);
        assert(session.tunnel.Snapshot().errors.unobservable_profiles.size() == 2);
        session_strategy->observation_errors.erase(p.id);
        session.tunnel.Refresh();
        Wait(session);
        assert(session.tunnel.Snapshot().errors.unobservable_profiles.size() == 1);
        const auto retained_registrations = session_strategy->fake.Fetch();
        assert(std::any_of(retained_registrations.begin(), retained_registrations.end(), [](const auto &info) {
            return info.id == "broken-orphan";
        }));
        session_strategy->fail_connect = false;
        session.tunnel.Connect(p);
        Wait(session);
        session.tunnel.Disconnect(p.id);
        Wait(session);
        session_strategy->fail_connect = true;
        session.tunnel.Connect(p);
        Wait(session);
        assert(session.tunnel.Snapshot().errors.operation);
        session.ClearOperationErrors();
        session_strategy->fail_connect = false;

        auto gate = std::make_shared<Gate>();
        auto entered = gate->entered.get_future();
        Tests::ObservableFixture queued(std::make_unique<FileProfileRepository>(root / "profiles"),
                          importer, std::make_unique<Partout::Tunnel>(std::make_unique<BlockingTunnel>(gate)));
        Wait(queued);
        queued.tunnel.Connect(Example(p.id));
        assert(entered.wait_for(std::chrono::seconds(5)) == std::future_status::ready);
        assert(queued.tunnel.Snapshot().busy);
        assert(!queued.profiles.Snapshot().busy);
        queued.tunnel.Disconnect(p.id);
        assert(queued.executor.CurrentActivity().busy);
        gate->release.set_value();
        Wait(queued);
        assert(!queued.tunnel.Snapshot().busy && !queued.profiles.Snapshot().busy);
        assert(!queued.profiles.Snapshot().operation_error.has_value());
        assert(queued.tunnel.Snapshot().tunnels.at(0).status.value == Status::disconnected);

        auto delayed = std::make_unique<ControlledTunnel>();
        delayed->fake.Save(p);
        delayed->fake.Connect(p.id);
        delayed->delayed_disconnect = true;
        auto *delayed_strategy = delayed.get();
        Tests::ObservableFixture removal(std::make_unique<FileProfileRepository>(root / "profiles"),
            importer, std::make_unique<Partout::Tunnel>(std::move(delayed)));
        Wait(removal);
        removal.profiles.Remove({p.id});
        Wait(removal);
        assert(!removal.profiles.Snapshot().operation_error.has_value());
        assert(removal.tunnel.Snapshot().available);
        assert(!removal.tunnel.Snapshot().errors.operation);
        assert(removal.profiles.Snapshot().profiles.empty());
        assert(reopened.Fetch().empty());
        // Keep the Windows registration until disconnect actually finishes.
        assert(delayed_strategy->fake.Fetch().size() == 1);
        delayed_strategy->fake.SetStatus(p.id, Partout::Models::TunnelStatus::inactive);
        removal.tunnel.Refresh();
        Wait(removal);
        assert(removal.tunnel.Snapshot().available);
        assert(removal.tunnel.Snapshot().tunnels.empty());
        assert(!removal.tunnel.Snapshot().errors.operation);
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
