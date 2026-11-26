// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/extensions/Models+Business.h"
#include "../business/models/InteractiveLogin.h"
#include "Worker.h"
#include "../business/managers/ProfileManager.h"
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

    TunnelObservable(Worker &executor, std::unique_ptr<Partout::Tunnel> tunnel, ProfileManager &profiles);
    ~TunnelObservable();
    void Cancel();
    // Returns a login request without connecting when credentials are needed.
    std::optional<InteractiveLogin> Connect(Profile profile, std::optional<Partout::TunnelCredentials> credentials = {});
    void Disconnect(std::string id);
    void Refresh();
    void ClearOperationError();
    State Snapshot() const;
private:
    void OnUpdate(const Models::Event &event);
    void Remove(std::string id);
    ProfileManager &profiles_;
    std::size_t profile_subscription_;
    void Post(std::function<void()> operation, bool foreground = true);
    void Publish();
    Worker &executor_;
    std::unique_ptr<Partout::Tunnel> tunnel_;
    mutable std::mutex mutex_;
    State snapshot_;
};
}
