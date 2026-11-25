// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "UserPreferencesObservable.h"
#include <stdexcept>

namespace Passepartout {
UserPreferencesObservable::UserPreferencesObservable(std::unique_ptr<PreferencesRepository> repository,
    std::function<bool()> can_change_private_data)
    : repository_(std::move(repository)), preferences_(Preferences::Defaults()), can_change_private_data_(std::move(can_change_private_data)) {
    try {
        preferences_ = repository_->Fetch();
    } catch (...) {
        load_error_ = true;
    }
}

Models::AppPreferences UserPreferencesObservable::Snapshot() const {
    std::lock_guard lock(mutex_);
    return preferences_;
}

bool UserPreferencesObservable::HasLoadError() const {
    std::lock_guard lock(mutex_);
    return load_error_;
}

void UserPreferencesObservable::Update(std::function<void(Models::AppPreferences &)> edit) {
    std::lock_guard write_lock(write_mutex_);
    auto updated = Snapshot();
    edit(updated);
    repository_->Save(updated);
    std::function<void(const Models::AppPreferences &)> apply;
    {
        std::lock_guard lock(mutex_);
        preferences_ = updated;
        load_error_ = false;
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
    return can_change_private_data_();
}

void UserPreferencesObservable::SetLastCheckedVersion(std::int64_t timestamp, std::optional<std::string> version) {
    Update([timestamp, version = std::move(version)](auto &preferences) {
        preferences.lastCheckedVersionTimestamp = timestamp;
        preferences.lastCheckedVersion = version;
    });
}

void UserPreferencesObservable::OnChange(std::function<void(const Models::AppPreferences &)> apply) {
    std::lock_guard write_lock(write_mutex_);
    {
        std::lock_guard lock(mutex_);
        apply_ = apply;
    }
    if (apply) apply(Snapshot());
}
}
