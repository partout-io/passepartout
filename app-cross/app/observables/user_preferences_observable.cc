// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "user_preferences_observable.h"
#include <stdexcept>

namespace Passepartout {
UserPreferencesObservable::UserPreferencesObservable(std::unique_ptr<PreferencesRepository> repository,
    std::function<bool()> canChangePrivateData)
    : repository_(std::move(repository)), preferences_(DefaultPreferences()), canChangePrivateData_(std::move(canChangePrivateData)) {
    try {
        preferences_ = repository_->Fetch();
    } catch (...) {
        loadError_ = true;
    }
}
Models::AppPreferences UserPreferencesObservable::Snapshot() const {
    std::lock_guard lock(mutex_);
    return preferences_;
}
bool UserPreferencesObservable::HasLoadError() const {
    std::lock_guard lock(mutex_);
    return loadError_;
}
void UserPreferencesObservable::Update(std::function<void(Models::AppPreferences &)> edit) {
    std::lock_guard writeLock(writeMutex_);
    auto updated = Snapshot();
    edit(updated);
    repository_->Save(updated);
    std::function<void(const Models::AppPreferences &)> apply;
    {
        std::lock_guard lock(mutex_);
        preferences_ = updated;
        loadError_ = false;
        apply = apply_;
    }
    // Preserve write order while allowing observers to read the published state.
    if (apply) apply(updated);
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
    return canChangePrivateData_();
}
void UserPreferencesObservable::SetLastCheckedVersion(std::int64_t timestamp, std::optional<std::string> version) {
    Update([timestamp, version = std::move(version)](auto &preferences) {
        preferences.lastCheckedVersionTimestamp = timestamp;
        preferences.lastCheckedVersion = version;
    });
}
void UserPreferencesObservable::OnChange(std::function<void(const Models::AppPreferences &)> apply) {
    std::lock_guard writeLock(writeMutex_);
    {
        std::lock_guard lock(mutex_);
        apply_ = apply;
    }
    if (apply) apply(Snapshot());
}
}
