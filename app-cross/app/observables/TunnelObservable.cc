// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "TunnelObservable.h"
#include "../business/managers/AppSession.h"
#include <algorithm>

namespace Passepartout {
void TunnelObservable::Connect(std::string id) {
    if (interactive_login_) return;
    const auto profile = session_.FindProfile(id);
    if (!profile) return;
    interactive_login_ = InteractiveLogin::FromProfile(*profile);
    if (!interactive_login_) session_.Connect(std::move(id));
}

TunnelObservable::ToggleState TunnelObservable::StateForProfile(const AppSnapshot &state, const std::string &id) {
    ToggleState result;
    for (const auto &tunnel : state.tunnels) {
        if (tunnel.id == id) {
            result.is_on = tunnel.isEnabled;
            result.status = tunnel.status.value;
        }
    }
    const bool exists = std::any_of(state.profiles.begin(), state.profiles.end(), [&](const auto &profile) {
        return profile.id == id;
    });
    result.can_interact = exists && state.loaded && !state.foreground_busy && !state.pending_profile && state.tunnel_available &&
        std::find(state.recovering_profiles.begin(), state.recovering_profiles.end(), id) == state.recovering_profiles.end() &&
        state.tunnel_observation_errors.find(id) == state.tunnel_observation_errors.end() &&
        result.status != Status::disconnecting;
    return result;
}

void TunnelObservable::SetEnabled(const std::string &id, bool enabled) {
    const auto state = StateForProfile(Snapshot(), id);
    if (!state.can_interact || state.is_on == enabled) return;
    if (enabled) Connect(id);
    else Disconnect(id);
}

std::optional<InteractiveLogin> TunnelObservable::TakeInteractiveLogin() {
    auto login = std::move(interactive_login_);
    interactive_login_.reset();
    return login;
}

void TunnelObservable::CompleteInteractiveLogin(InteractiveLogin login) {
    if (!login.CanSubmit() || !StateForProfile(Snapshot(), login.original.id).can_interact) return;
    const auto id = login.original.id;
    session_.Connect(id, std::move(login.credentials), std::move(login.original));
}

void TunnelObservable::Disconnect(std::string id) {
    session_.Disconnect(std::move(id));
}

void TunnelObservable::Refresh() {
    session_.Refresh();
}

AppSnapshot TunnelObservable::Snapshot() const {
    return session_.Snapshot();
}
}
