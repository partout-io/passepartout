// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "UserPreferencesObservable.h"
#include <stdexcept>

namespace Passepartout {
UserPreferencesObservable::UserPreferencesObservable(
    std::shared_ptr<PreferencesStore> store,
    std::function<bool()> can_change_private_data
)
    : store_(std::move(store)), can_change_private_data_(std::move(can_change_private_data)) {
    MainThread::Assert();
}

Models::AppPreferences UserPreferencesObservable::Snapshot() const {
    MainThread::Assert();
    return store_->Fetch();
}

bool UserPreferencesObservable::HasLoadError() const {
    MainThread::Assert();
    return store_->HasLoadError();
}

void UserPreferencesObservable::Update(std::function<void(Models::AppPreferences &)> edit) {
    MainThread::Assert();
    const auto updated = store_->Update(edit);
    // Preserve write order while allowing observers to read the published state.
    if (apply_) apply_(updated);
    changes.Emit();
}

void UserPreferencesObservable::SetDNSFallback(bool enabled) {
    MainThread::Assert();
    Update([enabled](auto &preferences) {
        preferences.dnsFallsBack = enabled;
    });
}

void UserPreferencesObservable::SetLogsPrivateData(bool enabled) {
    MainThread::Assert();
    if (!CanChangePrivateData()) throw std::runtime_error("Disable all profiles before changing private logging.");
    Update([enabled](auto &preferences) {
        preferences.logsPrivateData = enabled;
    });
}

bool UserPreferencesObservable::CanChangePrivateData() const {
    MainThread::Assert();
    return !can_change_private_data_ || can_change_private_data_();
}

void UserPreferencesObservable::OnChange(ChangeHandler apply) {
    MainThread::Assert();
    apply_ = std::move(apply);
    if (apply_) apply_(Snapshot());
}
}
