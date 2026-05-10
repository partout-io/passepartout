// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi.helpers

data class ABIResult(
    val code: Int,
    val payload: String?
) {
    fun getOrThrow() {
        if (code != 0) {
            throw ABIException(code, payload)
        }
    }
}
