// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileObservable.h"
#include "../business/managers/AppSession.h"
#include <algorithm>

namespace Passepartout {
bool ProfileObservable::CanSave(const AppSnapshot &state, const std::string &id) {
    return CanRemove(state, {id});
}

std::shared_ptr<ProfileEditor> ProfileObservable::CreateEditor(const std::string &id) const {
    const auto profile = session_.FindProfile(id);
    return profile ? std::make_shared<ProfileEditor>(*profile) : nullptr;
}

void ProfileObservable::SaveEditor(std::shared_ptr<ProfileEditor> editor) {
    if (!editor || !CanSave(Snapshot(), editor->Original().id) || !editor->BeginSave()) return;
    try {
        if (session_.SaveProfile(editor->Original(), editor->Snapshot().draft, [editor](bool succeeded) {
            editor->FinishSave(succeeded);
        })) return;
    } catch (...) {
        editor->FinishSave(false);
        throw;
    }
    editor->FinishSave(false);
}

bool ProfileObservable::CanRemove(const AppSnapshot &state, const std::vector<std::string> &ids) {
    if (!state.loaded || state.foreground_busy || state.pending_profile || ids.empty()) return false;
    return std::all_of(ids.begin(), ids.end(), [&](const auto &id) {
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
