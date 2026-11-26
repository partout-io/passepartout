// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/extensions/Models+Business.h"
#include "../business/models/InteractiveLogin.h"
#include "Worker.h"
#include <partout/tunnel/Tunnel.h>

namespace Passepartout {
class TunnelObservable final {
public:
    struct State final {
        std::vector<Models::AppTunnelInfo> tunnels;
        std::map<std::string, std::string> observation_errors;
        bool available = false;
        std::optional<std::string> pending_profile;
        std::string operation_error;
        std::string observation_error;
        std::uint64_t revision = 0;
        Worker::Activity activity;
        bool HasActivity() const;
    };

    struct ToggleState final {
        bool is_on = false;
        bool can_interact = false;
        Status status = Status::disconnected;
    };
    TunnelObservable(Worker &executor, std::unique_ptr<Partout::Tunnel> tunnel);
    void Cancel();
    static ToggleState StateForProfile(const State &state, const std::string &id);
    void SetEnabled(Profile profile, bool enabled);
    void Connect(Profile profile);
    // Connect with credentials already collected by the presentation layer.
    void ConnectProfile(Profile profile, std::optional<Partout::TunnelCredentials> credentials = {});
    std::optional<InteractiveLogin> TakeInteractiveLogin();
    void CompleteInteractiveLogin(InteractiveLogin login);
    void Disconnect(std::string id);
    void Remove(std::string id);
    void Refresh();
    void ClearOperationError();
    State Snapshot() const;
private:
    void Post(std::function<void()> operation, bool foreground = true);
    void Publish();
    Worker &executor_;
    std::unique_ptr<Partout::Tunnel> tunnel_;
    std::optional<InteractiveLogin> interactive_login_;
    mutable std::mutex mutex_;
    State snapshot_;
};
}
