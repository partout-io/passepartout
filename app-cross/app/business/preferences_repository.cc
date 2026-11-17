// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "preferences_repository.h"
#include "partout.h"

namespace Passepartout {
Models::AppPreferences DefaultPreferences() {
    Models::AppPreferences preferences{};
    preferences.dnsFallsBack = true;
    preferences.cryptoBackend = PartoutCryptoMbedTLS;
    return preferences;
}
}
