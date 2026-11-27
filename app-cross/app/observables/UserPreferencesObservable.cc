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
    : store_(std::move(store)), can_change_private_data_(std::move(can_change_private_data)) {}

Models::AppPreferences UserPreferencesObservable::Snapshot() const {
    return store_->Fetch();
}

bool UserPreferencesObservable::HasLoadError() const {
    return store_->HasLoadError();
}

void UserPreferencesObservable::Update(std::function<void(Models::AppPreferences &)> edit) {
    std::lock_guard write_lock(write_mutex_);
    const auto updated = store_->Update(edit);
    // Preserve write order while allowing observers to read the published state.
    if (apply_) apply_(updated);
    changes.Emit();
}

void UserPreferencesObservable::SetDNSFallback(bool enabled) {
    Update([enabled](auto &preferences) {
        preferences.dnsFallsBack = enabled;
    });
}

void UserPreferencesObservable::SetLogsPrivateData(bool enabled) {
    if (!CanChangePrivateData()) throw std::runtime_error("Disable all profiles before changing private logging.");
    Update([enabled](auto &preferences) {
        preferences.logsPrivateData = enabled;
    });
}

bool UserPreferencesObservable::CanChangePrivateData() const {
    return !can_change_private_data_ || can_change_private_data_();
}

void UserPreferencesObservable::OnChange(ChangeHandler apply) {
    std::lock_guard write_lock(write_mutex_);
    apply_ = std::move(apply);
    if (apply_) apply_(Snapshot());
}
}
