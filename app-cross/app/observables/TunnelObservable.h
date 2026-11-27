// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "MainThread.h"
#include "../business/extensions/EventEmitter.h"
#include "../business/extensions/Models+Business.h"
#include "../business/models/InteractiveLogin.h"
#include "Worker.h"
#include "../business/managers/ProfileManager.h"
#include <partout/tunnel/Tunnel.h>
#include <set>

namespace Passepartout {
class TunnelObservable final {
public:
    EventEmitter<> changes;
    struct Errors final {
        bool operation = false;
        std::set<std::string> unobservable_profiles;
    };

    struct State final {
        std::vector<Models::AppTunnelInfo> tunnels;
        std::optional<std::string> pending_profile;
        bool available = false;
        // Queued/running actions only; observation polling is not activity.
        bool busy = false;
        Errors errors;
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
    MainThread delivery_;
    void OnUpdate(const Models::Event &event);
    void Remove(std::string id);
    ProfileManager &profiles_;
    std::size_t profile_subscription_;
    void Post(std::function<void()> operation, bool foreground = true);
    void FinishOperation();
    Worker &executor_;
    std::unique_ptr<Partout::Tunnel> tunnel_;
    State snapshot_;
    std::size_t pending_operations_ = 0;
};
}
