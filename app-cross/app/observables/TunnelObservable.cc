// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "TunnelObservable.h"
#include "../business/managers/AppSession.h"
#include <algorithm>

namespace Passepartout {
void TunnelObservable::Connect(std::string id) {
    if (interactiveLogin_) return;
    const auto editor = session_.CreateEditor(id);
    if (!editor) return;
    interactiveLogin_ = InteractiveLogin::FromProfile(editor->Original());
    if (!interactiveLogin_) session_.Connect(std::move(id));
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
std::optional<InteractiveLogin> TunnelObservable::TakeInteractiveLogin() {
    auto login = std::move(interactiveLogin_);
    interactiveLogin_.reset();
    return login;
}
void TunnelObservable::CompleteInteractiveLogin(InteractiveLogin login) {
    if (!login.CanSubmit() || !StateForProfile(Snapshot(), login.original.id).canInteract) return;
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
