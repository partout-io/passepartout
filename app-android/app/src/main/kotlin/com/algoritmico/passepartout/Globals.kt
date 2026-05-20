// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.content.Context
import kotlinx.serialization.json.Json

object Globals {
    val json = Json {
        ignoreUnknownKeys = true
    }

    const val logTag = "Passepartout"
    const val serviceLogTag = "PassepartoutVpnService"

    // FIXME: Build bundle dynamically
    const val BUNDLE_FILENAME = "bundle.json"
    const val CONSTANTS_FILENAME = "constants.json"
    const val PROFILES_DIRECTORY = "profiles-v1"
    const val PROFILE_LAST_PATH = "tunnel_profile.json"

    const val EVENT_BUFFER_CAPACITY = 64
    const val EVENT_REPLAY = 64
}

fun Context.readAsset(name: String): String {
    return assets.open(name).bufferedReader().use { it.readText() }
}