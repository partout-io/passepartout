// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "TunnelObservable.h"
#include "AppSession.h"
#include <algorithm>

namespace Passepartout {
void TunnelObservable::Connect(std::string id) {
    session_.Connect(std::move(id));
}
TunnelObservable::ToggleState TunnelObservable::StateForProfile(const AppSnapshot &state, const std::string &id) {
    ToggleState result;
    for (const auto &tunnel : state.tunnels) {
        if (tunnel.id == id) {
            result.isOn = tunnel.isEnabled;
            result.status = tunnel.status.value;
        }
    }
    const bool exists = std::any_of(state.profiles.begin(), state.profiles.end(), [&](const auto &profile) {
        return profile.id == id;
    });
    result.canInteract = exists && state.loaded && !state.foregroundBusy && !state.pendingProfile && state.tunnelAvailable &&
        std::find(state.recoveringProfiles.begin(), state.recoveringProfiles.end(), id) == state.recoveringProfiles.end() &&
        state.tunnelObservationErrors.find(id) == state.tunnelObservationErrors.end() &&
        result.status != Status::disconnecting;
    return result;
}
void TunnelObservable::SetEnabled(const std::string &id, bool enabled) {
    const auto state = StateForProfile(Snapshot(), id);
    if (!state.canInteract || state.isOn == enabled) return;
    if (enabled) Connect(id);
    else Disconnect(id);
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
