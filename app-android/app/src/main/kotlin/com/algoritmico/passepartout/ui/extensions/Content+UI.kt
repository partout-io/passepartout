// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.extensions

internal fun hasContent(vararg values: Any?): Boolean = values.any { value ->
    when (value) {
        null -> false
        is Collection<*> -> value.isNotEmpty()
        is String -> value.isNotEmpty()
        else -> true
    }
}
