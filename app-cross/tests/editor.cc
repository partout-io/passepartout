// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "business/file_profile_repository.h"
#include "business/file_profile_journal.h"
#include "business/fake_tunnel_strategy.h"
#include "observables/profile_editor.h"
#include "observables/profile_observable.h"
#include "observables/session.h"
#include <cassert>
#include <chrono>
#include <fstream>
#include <iostream>
#include "support.h"

using namespace Passepartout;
namespace {
Profile Example() {
    Profile profile{};
    profile.id = "editor-id";
    profile.name = "Original";
    Partout::Models::TaggedModuleOpenVpn openvpn{};
    openvpn.value.id = "openvpn-id";
    Partout::Models::OpenVpnCredentials credentials{};
    credentials.username = "before";
    credentials.password = "old-secret";
    credentials.otpMethod.value = Partout::Models::OpenVpnCredentialsOTPMethod::none;
    credentials.otp = "preserved-otp";
    openvpn.value.credentials = credentials;
    openvpn.value.requiresInteractiveCredentials = true;
    profile.modules.push_back(openvpn);
    Partout::Models::TaggedModuleCustom custom{};
    custom.value.innerType.value = Partout::Models::ModuleType::Provider;
    custom.value.json = {{"id", "hidden"}, {"opaque", {1, 2, 3}}};
    profile.modules.push_back(custom);
    profile.activeModulesIds = {"openvpn-id", "hidden"};
    profile.userInfo = {{"unknown-metadata", "keep"}};
    return profile;
}
void Wait(AppSession &session) {
    assert(session.WaitIdle(std::chrono::seconds(5)));
}
class RejectingTunnel final : public TunnelStrategy {
public:
    FakeTunnelStrategy fake;
    bool rejects = false;
    Profile saved;
    unsigned saves = 0;
    std::vector<Models::AppTunnelInfo> Fetch() override {
        return fake.Fetch();
    }
    void Save(const Profile &profile) override {
        ++saves;
        if (rejects) throw std::runtime_error("Save rejected");
        saved = profile;
        fake.Save(profile);
    }
    void Connect(const std::string &id) override {
        fake.Connect(id);
    }
    void Disconnect(const std::string &id) override {
        fake.Disconnect(id);
    }
    void Remove(const std::string &id) override {
        fake.Remove(id);
    }
};
}
int main() {
    InitializeTests();
    const auto original = Example();
    ProfileEditor editor(original);
    assert(!editor.CanSave());
    editor.Rename(" \t\n");
    assert(!editor.CanSave());
    editor.Rename("Renamed");
    auto module = std::get<Partout::Models::TaggedModuleOpenVpn>(editor.Snapshot().draft.modules.front());
    module.value.credentials->username = "new-user";
    module.value.credentials->password = "new-secret";
    editor.UpdateModule(module);
    assert(editor.CanSave());
    assert(editor.BeginSave());
    assert(!editor.BeginSave());
    editor.Rename("Ignored while saving");
    assert(editor.Snapshot().draft.name == "Renamed");
    editor.FinishSave(false);
    assert(editor.CanSave() && editor.Snapshot().failed);
    const auto draft = editor.Snapshot().draft;
    assert(draft.id == original.id && draft.userInfo == original.userInfo);
    assert(draft.modules.back() == original.modules.back());
    assert(draft.activeModulesIds == original.activeModulesIds);
    assert(std::get<Partout::Models::TaggedModuleOpenVpn>(draft.modules.front()).value.credentials->otp == "preserved-otp");

    const auto root = std::filesystem::temp_directory_path() /
        ("passepartout-editor-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    std::filesystem::create_directories(root);
    try {
        const auto store = root / "profiles";
        const auto journalPath = store / "transactions";
        FileProfileRepository repository(store);
        repository.Save(original);
        FileProfileJournal journal(journalPath);
        // Interrupted replacement: the authoritative local object may already
        // contain the draft. Startup rolls both stores back before allowing edits.
        journal.Save({original.id, original, false});
        repository.Save(draft);
        auto strategy = std::make_unique<RejectingTunnel>();
        auto *backend = strategy.get();
        backend->fake.Save(draft);
        AppSession session(std::make_unique<FileProfileRepository>(store), {}, std::move(strategy),
            std::make_shared<AppLogger>(), std::make_unique<FileProfileJournal>(journalPath),
            std::chrono::milliseconds(0));
        Wait(session);
        assert(repository.Fetch().front() == original && backend->saved == original);
        assert(journal.Fetch().empty());
        ProfileObservable profiles(session);
        auto pending = profiles.CreateEditor(original.id);
        assert(pending);
        pending->Rename("Retry name");
        backend->rejects = true;
        profiles.SaveEditor(pending);
        Wait(session);
        assert(pending->Snapshot().failed && pending->Snapshot().draft.name == "Retry name");
        assert(repository.Fetch().front() == original);
        assert(!session.Snapshot().recoveringProfiles.empty());
        assert(!ProfileObservable::CanSave(session.Snapshot(), original.id));
        backend->rejects = false;
        session.Refresh();
        Wait(session);
        assert(journal.Fetch().empty());
        profiles.SaveEditor(pending);
        Wait(session);
        assert(pending->Snapshot().saved);
        assert(repository.Fetch().front().name == "Retry name");
        assert(backend->saved.name == "Retry name");
        assert(backend->fake.Fetch().front().status.value == Status::disconnected);
        // An old editor cannot silently overwrite a more recent save.
        auto stale = std::make_shared<ProfileEditor>(original);
        stale->Rename("Stale");
        session.SaveEditor(stale);
        Wait(session);
        assert(stale->Snapshot().failed && repository.Fetch().front().name == "Retry name");
        backend->fake.Connect(original.id);
        session.Refresh();
        Wait(session);
        assert(!ProfileObservable::CanSave(session.Snapshot(), original.id));
        backend->fake.Disconnect(original.id);
        // Interrupted import rolls back; an untracked native entry is retained.
        auto imported = original;
        imported.id = "interrupted-import";
        repository.Save(imported);
        backend->fake.Save(imported);
        journal.Save({imported.id, std::nullopt, false});
        auto untracked = original;
        untracked.id = "untracked";
        backend->fake.Save(untracked);
        session.Load();
        Wait(session);
        assert(repository.Fetch().size() == 1);
        assert(journal.Fetch().empty());
        assert(backend->fake.Fetch().size() == 2);
        // Deletion intent survives a new manager and completes without a local object.
        journal.Save({original.id, std::nullopt, true});
        session.Load();
        Wait(session);
        assert(repository.Fetch().empty() && journal.Fetch().empty());
        assert(backend->fake.Fetch().size() == 1);
    } catch (const std::exception &error) {
        std::cerr << error.what() << std::endl;
        std::filesystem::remove_all(root);
        return 1;
    }
    std::filesystem::remove_all(root);
    std::cout << "Editor drafts, native save failure/retry, conflicts and transaction recovery passed.\n";
}
