// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "business/strategy/FileProfileRepository.h"
#include "business/strategy/FakeTunnelStrategy.h"
#include "observables/ProfileEditor.h"
#include "business/models/InteractiveLogin.h"
#include "observables/TunnelObservable.h"
#include "observables/ProfileObservable.h"
#include "ObservableFixture.h"
#include <cassert>
#include <chrono>
#include <fstream>
#include <iostream>
#include "Support.h"

namespace {
Passepartout::Profile Example() {
    Passepartout::Profile profile{};
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
    custom.value.json = {{"id", "hidden"}, {"opaque", std::vector<int>{1, 2, 3}}};
    profile.modules.push_back(custom);
    profile.activeModulesIds = {"openvpn-id", "hidden"};
    profile.userInfo = {{"unknown-metadata", "keep"}};
    return profile;
}

void Wait(Passepartout::Tests::ObservableFixture &session) {
    assert(session.executor.WaitIdle(std::chrono::seconds(5)));
}
class RejectingTunnel final : public Partout::TunnelStrategy {
public:
    Passepartout::FakeTunnelStrategy fake;
    bool rejects = false;
    Passepartout::Profile saved;
    unsigned saves = 0;
    std::optional<Partout::TunnelCredentials> connection_credentials;
    std::vector<Partout::Models::TunnelSnapshot> Fetch() override {
        return fake.Fetch();
    }

    void Save(const Passepartout::Profile &profile) override {
        ++saves;
        if (rejects) throw std::runtime_error("Save rejected");
        saved = profile;
        fake.Save(profile);
    }

    void Connect(const std::string &id) override {
        fake.Connect(id);
    }

    void ConnectWithCredentials(const std::string &id, const Partout::TunnelCredentials &credentials) override {
        connection_credentials = credentials;
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

using namespace Passepartout;
int main() {
    InitializeTests();
    const auto original = Example();
    auto login = InteractiveLogin::FromProfile(original);
    assert(login && !login->needs_otp && login->CanSubmit());
    assert(login->credentials.username == "before");
    login->credentials.username = "  ";
    assert(!login->CanSubmit());
    auto inactive = original;
    inactive.activeModulesIds.clear();
    assert(!InteractiveLogin::FromProfile(inactive));
    auto otp_profile = original;
    auto &otp_module = std::get<Partout::Models::TaggedModuleOpenVpn>(otp_profile.modules.front()).value;
    otp_module.credentials->otpMethod.value = Partout::Models::OpenVpnCredentialsOTPMethod::append;
    auto otp_login = InteractiveLogin::FromProfile(otp_profile);
    assert(otp_login && otp_login->needs_otp && !otp_login->CanSubmit());
    assert(otp_login->credentials.password.empty());
    assert(otp_login->credentials.username == "before");
    otp_login->credentials.password = "123456";
    assert(otp_login->CanSubmit());
    assert(otp_module.credentials->password == "old-secret");
    otp_module.requiresInteractiveCredentials = false;
    assert(!InteractiveLogin::FromProfile(otp_profile));
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
    assert(editor.CanSave() && editor.Snapshot().operation_failed);
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
        FileProfileRepository repository(store);
        repository.Save(original);
        auto strategy = std::make_unique<RejectingTunnel>();
        auto *backend = strategy.get();
        backend->fake.Save(draft); // Startup synchronizes the authoritative saved profile.
        Tests::ObservableFixture session(std::make_unique<FileProfileRepository>(store), {}, std::make_unique<Partout::Tunnel>(std::move(strategy)));
        Wait(session);
        assert(repository.Fetch().front() == original && backend->saved == original);
        auto &profiles = session.profiles;
        auto &tunnel = session.tunnel;
        tunnel.Connect(original.id);
        auto canceled_login = tunnel.TakeInteractiveLogin();
        assert(canceled_login && !tunnel.TakeInteractiveLogin());
        assert(!backend->connection_credentials);
        assert(backend->fake.Fetch().front().status.value == Partout::Models::TunnelStatus::inactive);
        canceled_login.reset();
        tunnel.Connect(original.id);
        auto submitted_login = tunnel.TakeInteractiveLogin();
        assert(submitted_login);
        submitted_login->credentials.password = "connection-only-secret";
        tunnel.CompleteInteractiveLogin(std::move(*submitted_login));
        Wait(session);
        assert(backend->connection_credentials->password == "connection-only-secret");
        assert(repository.Fetch().front() == original && backend->saved == original);
        tunnel.Disconnect(original.id);
        Wait(session);
        auto pending = profiles.CreateEditor(original.id);
        assert(pending);
        assert(!profiles.CreateEditor("missing-profile"));
        assert(!session.profiles.FindProfile("missing-profile"));
        pending->Rename("Retry name");
        backend->rejects = true;
        profiles.SaveEditor(pending);
        Wait(session);
        assert(pending->Snapshot().saved && !pending->Snapshot().operation_failed);
        assert(repository.Fetch().front().name == "Retry name");
        assert(!session.tunnel.Snapshot().synchronization_error.empty());
        assert(ProfileObservable::CanSave(session.profiles.Snapshot(), original.id));
        backend->connection_credentials.reset();
        session.tunnel.ConnectProfile(original.id);
        Wait(session);
        assert(!session.tunnel.Snapshot().operation_error.empty());
        assert(!backend->connection_credentials);
        assert(backend->fake.Fetch().front().status.value == Partout::Models::TunnelStatus::inactive);
        session.ClearOperationErrors();
        backend->rejects = false;
        session.tunnel.Refresh();
        Wait(session);
        assert(session.tunnel.Snapshot().synchronization_error.empty());
        assert(pending->Snapshot().saved);
        assert(repository.Fetch().front().name == "Retry name");
        assert(backend->saved.name == "Retry name");
        assert(backend->fake.Fetch().front().status.value == Partout::Models::TunnelStatus::inactive);
        // An old editor cannot silently overwrite a more recent save.
        auto stale = std::make_shared<ProfileEditor>(original);
        stale->Rename("Stale");
        profiles.SaveEditor(stale);
        Wait(session);
        assert(stale->Snapshot().operation_failed && repository.Fetch().front().name == "Retry name");
        backend->fake.Connect(original.id);
        session.tunnel.Refresh();
        Wait(session);
        assert(ProfileObservable::CanSave(session.profiles.Snapshot(), original.id));
        auto active_editor = profiles.CreateEditor(original.id);
        active_editor->Rename("Saved while active");
        profiles.SaveEditor(active_editor);
        Wait(session);
        assert(active_editor->Snapshot().saved);
        assert(repository.Fetch().front().name == "Saved while active");
        assert(backend->saved.name == "Retry name");
        backend->fake.Disconnect(original.id);
        session.tunnel.Refresh();
        Wait(session);
        assert(backend->saved.name == "Saved while active");
        // Reload synchronizes stored profiles and removes obsolete app-owned registrations.
        auto imported = original;
        imported.id = "saved-import";
        repository.Save(imported);
        auto untracked = original;
        untracked.id = "untracked";
        backend->fake.Save(untracked);
        session.profiles.Load();
        Wait(session);
        assert(repository.Fetch().size() == 2);
        assert(backend->fake.Fetch().size() == 2);
        session.profiles.Remove({original.id, imported.id});
        Wait(session);
        assert(repository.Fetch().empty());
        assert(backend->fake.Fetch().empty());
    } catch (const std::exception &error) {
        std::cerr << error.what() << std::endl;
        std::filesystem::remove_all(root);
        return 1;
    }
    std::filesystem::remove_all(root);
    std::cout << "Editor drafts, authoritative saves, tunnel synchronization and conflicts passed.\n";
}
