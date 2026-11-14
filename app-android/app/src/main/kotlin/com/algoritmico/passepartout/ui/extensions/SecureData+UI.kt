// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.extensions

import kotlin.io.encoding.Base64

fun String.base64ToHex(): String? = try {
    Base64.decode(this).toHexString()
} catch (_: IllegalArgumentException) {
    null
}
