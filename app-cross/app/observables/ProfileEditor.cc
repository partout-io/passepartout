// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileEditor.h"
#include <type_traits>

namespace Passepartout {
ProfileEditor::ProfileEditor(Profile profile) : original_(std::move(profile)), state_{original_} {}

ProfileEditor::State ProfileEditor::Snapshot() const {
    std::lock_guard lock(mutex_);
    return state_;
}

const Profile &ProfileEditor::Original() const {
    return original_;
}

void ProfileEditor::Rename(std::string name) {
    std::lock_guard lock(mutex_);
    if (state_.saving || state_.saved) return;
    state_.draft.name = std::move(name);
}

void ProfileEditor::UpdateModule(const Partout::Models::TaggedModule &module) {
    std::lock_guard lock(mutex_);
    if (state_.saving || state_.saved) return;
    std::visit([this](const auto &replacement) {
        using Module = std::decay_t<decltype(replacement)>;
        if constexpr (!std::is_same_v<Module, Partout::Models::TaggedModuleCustom>) {
            if (replacement.value.id.empty()) return;
            for (auto &module : state_.draft.modules) {
                auto *existing = std::get_if<Module>(&module);
                if (existing && existing->value.id == replacement.value.id) {
                    *existing = replacement;
                    return;
                }
            }
        }
    }, module);
}

bool ProfileEditor::IsValidChange() const {
    return !state_.saving && !state_.saved && state_.draft != original_ &&
        state_.draft.name.find_first_not_of(" \t\r\n") != std::string::npos;
}

bool ProfileEditor::CanSave() const {
    std::lock_guard lock(mutex_);
    return IsValidChange();
}

bool ProfileEditor::BeginSave() {
    std::lock_guard lock(mutex_);
    if (!IsValidChange()) return false;
    state_.saving = true;
    state_.operation_failed = false;
    return true;
}

void ProfileEditor::FinishSave(bool succeeded) {
    std::lock_guard lock(mutex_);
    state_.saving = false;
    state_.saved = succeeded;
    state_.operation_failed = !succeeded;
}

void ProfileEditor::ClearOperationError() {
    std::lock_guard lock(mutex_);
    state_.operation_failed = false;
}
}
