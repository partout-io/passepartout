// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi.helpers

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

suspend fun awaitCompletion(
    block: (ABICompletionCallback) -> Unit
) = withContext(Dispatchers.IO) {
    val result = CompletableDeferred<ABIResult>()
    block { code, json ->
        result.complete(ABIResult(code, json))
    }
    result.await().getOrThrow()
}

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
