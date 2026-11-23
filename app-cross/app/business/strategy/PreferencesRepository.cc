// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "PreferencesRepository.h"
#include "partout.h"

namespace Passepartout {
Models::AppPreferences Preferences::Defaults() {
    Models::AppPreferences preferences{};
    preferences.dnsFallsBack = true;
    preferences.cryptoBackend = PartoutCryptoMbedTLS;
    return preferences;
}
}
