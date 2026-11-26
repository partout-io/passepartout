// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "AppPreferences.h"

namespace Passepartout {
// Publish current app preferences through the platform's shared storage.
void StoreAppPreferences(const Models::AppPreferences &preferences);
}
