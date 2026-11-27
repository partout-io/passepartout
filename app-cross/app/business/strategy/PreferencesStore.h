// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "PreferencesRepository.h"
#include <functional>
#include <memory>
#include <mutex>

namespace Passepartout {
// Serializes all app preference mutations, including background version checks.
class PreferencesStore final {
public:
    explicit PreferencesStore(std::unique_ptr<PreferencesRepository> repository);
    Models::AppPreferences Fetch() const;
    bool HasLoadError() const;
    Models::AppPreferences Update(const std::function<void(Models::AppPreferences &)> &edit);
private:
    std::unique_ptr<PreferencesRepository> repository_;
    mutable std::mutex mutex_;
    Models::AppPreferences preferences_;
    bool load_error_ = false;
};
}
