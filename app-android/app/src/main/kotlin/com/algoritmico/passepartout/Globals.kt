// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.content.Context
import kotlinx.serialization.json.Json

val globalJsonCoder = Json {
    ignoreUnknownKeys = true
}

fun Context.readAsset(name: String): String {
    return assets.open(name).bufferedReader().use { it.readText() }
}
