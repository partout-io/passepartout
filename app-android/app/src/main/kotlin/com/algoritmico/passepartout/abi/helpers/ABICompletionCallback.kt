// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi.helpers

fun interface ABICompletionCallback {
    fun onComplete(code: Int, json: String?)
}
