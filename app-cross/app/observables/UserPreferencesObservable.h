// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "MainThread.h"
#include "../business/extensions/EventEmitter.h"
#include "../business/strategy/PreferencesStore.h"
#include <functional>
#include <memory>

namespace Passepartout {
class UserPreferencesObservable final {
public:
    EventEmitter<> changes;
    using ChangeHandler = std::function<void(const Models::AppPreferences &)>;
    explicit UserPreferencesObservable(
        std::shared_ptr<PreferencesStore> store,
        std::function<bool()> can_change_private_data = {}
    );
    Models::AppPreferences Snapshot() const;
    bool HasLoadError() const;
    void SetDNSFallback(bool enabled);
    void SetLogsPrivateData(bool enabled);
    bool CanChangePrivateData() const;
    void OnChange(ChangeHandler apply);
private:
    MainThread delivery_;
    void Update(std::function<void(Models::AppPreferences &)> edit);
    std::shared_ptr<PreferencesStore> store_;
    ChangeHandler apply_;
    std::function<bool()> can_change_private_data_;
};
}
