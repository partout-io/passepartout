// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/preferences_repository.h"
#include <functional>
#include <memory>
#include <mutex>

namespace Passepartout {
class UserPreferencesObservable {
public:
    explicit UserPreferencesObservable(std::unique_ptr<PreferencesRepository> repository,
        std::function<bool()> canChangePrivateData = [] { return true; });
    Models::AppPreferences Snapshot() const;
    bool HasLoadError() const;
    void SetDNSFallback(bool enabled);
    void SetLogsPrivateData(bool enabled);
    bool CanChangePrivateData() const;
    void SetLastCheckedVersion(std::int64_t timestamp, std::optional<std::string> version);
    void OnChange(std::function<void(const Models::AppPreferences &)> apply);
private:
    void Update(std::function<void(Models::AppPreferences &)> edit);
    std::unique_ptr<PreferencesRepository> repository_;
    std::mutex writeMutex_;
    mutable std::mutex mutex_;
    Models::AppPreferences preferences_;
    bool loadError_ = false;
    std::function<void(const Models::AppPreferences &)> apply_;
    std::function<bool()> canChangePrivateData_;
};
}
