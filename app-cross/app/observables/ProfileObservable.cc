// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileObservable.h"
#include "../business/managers/AppSession.h"
#include <algorithm>

namespace Passepartout {
bool ProfileObservable::CanSave(const AppSnapshot &state, const std::string &id) {
    if (!CanRemove(state, {id}) || !state.tunnel_available || state.tunnel_observation_errors.count(id)) return false;
    return std::none_of(state.tunnels.begin(), state.tunnels.end(), [&](const auto &tunnel) {
        return tunnel.id == id && (tunnel.isEnabled || tunnel.status.value != Status::disconnected);
    });
}

std::shared_ptr<ProfileEditor> ProfileObservable::CreateEditor(const std::string &id) const {
    return session_.CreateEditor(id);
}

void ProfileObservable::SaveEditor(std::shared_ptr<ProfileEditor> editor) {
    if (editor && CanSave(Snapshot(), editor->Original().id)) session_.SaveEditor(std::move(editor));
}

bool ProfileObservable::CanRemove(const AppSnapshot &state, const std::vector<std::string> &ids) {
    if (!state.loaded || state.foreground_busy || state.pending_profile || ids.empty()) return false;
    return std::all_of(ids.begin(), ids.end(), [&](const auto &id) {
        if (std::find(state.recovering_profiles.begin(), state.recovering_profiles.end(), id) != state.recovering_profiles.end())
            return false;
        return std::any_of(state.profiles.begin(), state.profiles.end(), [&](const auto &profile) {
            return profile.id == id;
        });
    });
}

void ProfileObservable::Load() {
    session_.Load();
}

void ProfileObservable::Import(std::vector<std::filesystem::path> paths) {
    session_.Import(std::move(paths));
}

void ProfileObservable::ImportFiles(std::shared_ptr<const ConfigurationFiles> files) {
    session_.ImportFiles(std::move(files));
}

void ProfileObservable::ImportFailed() {
    session_.ImportFailed();
}

void ProfileObservable::Remove(std::vector<std::string> ids) {
    if (!CanRemove(Snapshot(), ids)) return;
    session_.Remove(std::move(ids));
}

AppSnapshot ProfileObservable::Snapshot() const {
    return session_.Snapshot();
}

void ProfileObservable::ClearError() {
    session_.ClearError();
}
}
