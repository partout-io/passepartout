// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/extensions/Models+Business.h"
#include "../business/models/InteractiveLogin.h"
#include "../context/AppLog.h"
#include "SerialExecutor.h"
#include "AppPreferences.h"
#include <partout/tunnel/Tunnel.h>

namespace Passepartout {
class TunnelObservable final {
public:
    struct State final {
        std::vector<Models::AppTunnelInfo> tunnels;
        std::map<std::string, std::string> observation_errors;
        std::vector<std::string> profile_ids;
        bool profiles_loaded = false;
        bool available = false;
        std::optional<std::string> pending_profile;
        std::string operation_error;
        std::string observation_error;
        std::string synchronization_error;
        std::uint64_t revision = 0;
        SerialExecutor::Activity activity;
        bool HasActivity() const;
    };
    struct ToggleState {
        bool is_on = false;
        bool can_interact = false;
        Status status = Status::disconnected;
    };
    TunnelObservable(SerialExecutor &executor, std::unique_ptr<Partout::Tunnel> tunnel,
                     std::shared_ptr<AppLog> logger,
                     std::function<void(const Models::AppPreferences &)> apply_preferences = {}
    );
    void SetProfiles(std::vector<Profile> profiles, bool loaded);
    void ApplyPreferences(Models::AppPreferences preferences);
    void Cancel();
    static ToggleState StateForProfile(const State &state, const std::string &id);
    void SetEnabled(const std::string &id, bool enabled);
    void Connect(std::string id);
    // Connect with credentials already collected by the presentation layer.
    void ConnectProfile(std::string id, std::optional<Partout::TunnelCredentials> credentials = {});
    std::optional<InteractiveLogin> TakeInteractiveLogin();
    void CompleteInteractiveLogin(InteractiveLogin login);
    void Disconnect(std::string id);
    void Refresh();
    void ClearOperationError();
    State Snapshot() const;
private:
    bool Post(std::function<void()> operation, bool foreground = true, bool dispatch = false);
    void Observe();
    void Publish();
    std::string SynchronizeProfiles(const std::vector<Models::AppTunnelInfo> &tunnels);
    SerialExecutor &executor_;
    std::unique_ptr<Partout::Tunnel> tunnel_;
    std::shared_ptr<AppLog> logger_;
    std::function<void(const Models::AppPreferences &)> apply_preferences_;
    std::optional<Models::AppPreferences> pending_preferences_;
    std::map<std::string, Profile> synchronized_profiles_;
    std::vector<Profile> profiles_;
    std::optional<std::string> pending_profile_;
    std::optional<InteractiveLogin> interactive_login_;
    std::string last_observation_error_;
    std::string last_synchronization_error_;
    mutable std::mutex mutex_;
    State snapshot_;
};
}
