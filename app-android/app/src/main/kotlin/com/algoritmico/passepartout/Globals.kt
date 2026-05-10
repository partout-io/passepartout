// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import kotlinx.serialization.json.Json

val globalJsonCoder = Json {
    ignoreUnknownKeys = true
}
