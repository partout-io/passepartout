// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.extensions

import java.util.Locale

fun String.uuidText(): String = replace("-", "")
    .uppercase(Locale.ROOT)
    .chunked(16)
    .joinToString("\n") { row -> row.chunked(4).joinToString(" ") }
