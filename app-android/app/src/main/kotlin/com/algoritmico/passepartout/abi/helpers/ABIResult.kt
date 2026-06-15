// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi.helpers

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

data class ABIResult(
    val code: Int,
    val payload: String?
) {
    companion object {
        suspend fun await(
            block: (ABICompletionCallback) -> Unit
        ): ABIResult = withContext(Dispatchers.IO) {
            val future = CompletableDeferred<ABIResult>()
            block { code, json ->
                future.complete(ABIResult(code, json))
            }
            val result = future.await()
            if (result.code != 0) {
                throw ABIException(result.code, result.payload)
            }
            result
        }
    }
}