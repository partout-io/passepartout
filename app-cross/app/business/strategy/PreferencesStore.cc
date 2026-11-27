// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "PreferencesStore.h"
#include "../extensions/Models+Business.h"

namespace Passepartout {
PreferencesStore::PreferencesStore(std::unique_ptr<PreferencesRepository> repository)
    : repository_(std::move(repository)), preferences_(Preferences::Defaults()) {
    try {
        preferences_ = repository_->Fetch();
    } catch (...) {
        load_error_ = true;
    }
}

Models::AppPreferences PreferencesStore::Fetch() const {
    std::lock_guard lock(mutex_);
    return preferences_;
}

bool PreferencesStore::HasLoadError() const {
    std::lock_guard lock(mutex_);
    return load_error_;
}

Models::AppPreferences PreferencesStore::Update(const std::function<void(Models::AppPreferences &)> &edit) {
    std::lock_guard lock(mutex_);
    auto updated = preferences_;
    edit(updated);
    repository_->Save(updated);
    preferences_ = updated;
    load_error_ = false;
    return updated;
}
}
