// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileEditor.h"
#include <algorithm>
#include <type_traits>

namespace {
std::string ModuleId(const Partout::Models::TaggedModule &module) {
    return std::visit([](const auto &value) -> std::string {
        if constexpr (std::is_same_v<std::decay_t<decltype(value)>, Partout::Models::TaggedModuleCustom>) {
            return {};
        } else {
            return value.value.id;
        }
    }, module);
}
}

using Passepartout::ProfileEditor;

ProfileEditor::ProfileEditor(Profile profile) : original_(std::move(profile)) {
    state_.draft = original_;
}

ProfileEditor::State ProfileEditor::Snapshot() const {
    std::lock_guard lock(mutex_);
    return state_;
}

const Passepartout::Profile &ProfileEditor::Original() const {
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
    const auto id = ModuleId(module);
    if (id.empty()) return;
    for (auto &existing : state_.draft.modules) {
        if (ModuleId(existing) == id && existing.index() == module.index()) {
            existing = module;
            return;
        }
    }
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
    state_.failed = false;
    return true;
}

void ProfileEditor::FinishSave(bool succeeded) {
    std::lock_guard lock(mutex_);
    state_.saving = false;
    state_.saved = succeeded;
    state_.failed = !succeeded;
}

void ProfileEditor::ClearError() {
    std::lock_guard lock(mutex_);
    state_.failed = false;
}
