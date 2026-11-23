// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "AppPreferences.h"

namespace Passepartout {
namespace Preferences {
Models::AppPreferences Defaults();
}

class PreferencesRepository {
public:
    virtual ~PreferencesRepository() = default;
    virtual Models::AppPreferences Fetch() = 0;
    virtual void Save(const Models::AppPreferences &preferences) = 0;
};
}
