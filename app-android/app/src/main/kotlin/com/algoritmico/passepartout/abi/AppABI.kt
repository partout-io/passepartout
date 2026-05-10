// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi

import com.algoritmico.passepartout.abi.helpers.ABICompletionCallback
import com.algoritmico.passepartout.abi.helpers.ABIResult
import io.partout.abi.TaggedProfile
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

internal class AppABIProfile(
    private val library: PassepartoutWrapper
) : AppABIProfileProtocol {
    override suspend fun importText(text: String, filename: String) {
        awaitCompletion { completion ->
            library.appImportProfileText(text, filename, completion)
        }
        library.appOnForeground()
    }

    override suspend fun remove(profileId: String) {
        awaitCompletion { completion ->
            library.appDeleteProfile(profileId, completion)
        }
    }

    override suspend fun remove(profileIds: Collection<String>) {
        awaitCompletion { completion ->
            library.appDeleteProfiles(profileIds.toTypedArray(), completion)
        }
    }

    override fun profile(profileId: String): TaggedProfile? {
        // FIXME: Implement through C/JNI App ABI.
        return null
    }

    private suspend fun awaitCompletion(
        block: (ABICompletionCallback) -> Unit
    ) = withContext(Dispatchers.IO) {
        val result = CompletableDeferred<ABIResult>()
        block { code, json ->
            result.complete(ABIResult(code, json))
        }
        result.await().getOrThrow()
    }
}
