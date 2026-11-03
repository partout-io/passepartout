// SPDX-License-Identifier: GPL-3.0
#include "business/profiles.h"
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
    bool delayedDisconnect = false;
    std::vector<Models::AppTunnelInfo> Fetch() override {
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
    const auto root = std::filesystem::temp_directory_path() /
        ("passepartout-test-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    std::filesystem::create_directories(root);
    try {
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
        const auto damaged = root / "profiles/objects/profile-broken.json";
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
        assert(session.Snapshot().tunnels.at(0).status.value == Status::disconnected);
        session.ClearError();
        // Failed files do not prevent the rest of a batch being processed.
        const auto another = root / "another.conf";
        std::ofstream(another) << "another configuration";
        session.Import({root / "missing.conf", another});
        Wait(session);
        assert(!session.Snapshot().error.empty());
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
        AppSession removal(std::make_unique<FileProfileRepository>(root / "profiles"),
                           importer, std::move(delayed));
        Wait(removal);
        removal.Remove({p.id});
        Wait(removal);
        assert(!removal.Snapshot().error.empty());
        assert(removal.Snapshot().profiles.size() == 1);
        assert(reopened.Fetch().size() == 1);
    } catch (...) {
        std::filesystem::remove_all(root);
        throw;
    }
    std::filesystem::remove_all(root);
    std::cout << "Persistence, import, reconciliation and failure-state checks passed.\n";
}
