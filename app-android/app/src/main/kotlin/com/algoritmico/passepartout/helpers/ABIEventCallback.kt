// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.helpers

fun interface ABIEventCallback {
    fun onEvent(eventCtx: Any?, eventJSON: String)
}
