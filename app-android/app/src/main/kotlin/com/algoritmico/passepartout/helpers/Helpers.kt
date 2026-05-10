// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.helpers

import kotlinx.serialization.json.Json

val globalJsonCoder = Json {
    ignoreUnknownKeys = true
}

class ABIException(
    val code: Int,
    val payload: String?
) : RuntimeException("ABI call failed (code=$code): $payload")

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
