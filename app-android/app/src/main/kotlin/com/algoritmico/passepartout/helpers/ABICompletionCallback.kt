// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.helpers

fun interface ABICompletionCallback {
    fun onComplete(eventCtx: Any?, code: Int, errorMessage: String?)
}
