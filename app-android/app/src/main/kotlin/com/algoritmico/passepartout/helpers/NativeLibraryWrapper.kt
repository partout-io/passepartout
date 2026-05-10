// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.helpers

import android.util.Log
import io.partout.abi.TaggedProfile
import io.partout.jni.AndroidTunnelController
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class NativeLibraryWrapper : AppABIProfileProtocol {
    external fun partoutVersion(): String
    external fun appInit(
        bundle: String,
        constants: String,
        profilesDir: String,
        cacheDir: String,
        eventHandler: ABIEventHandler,
        completion: ABICompletionCallback
    )
    external fun appDeinit(completion: ABICompletionCallback)
    external fun appOnForeground()
    external fun appImportProfileText(
        text: String,
        name: String,
        completion: ABICompletionCallback
    )
    external fun appDeleteProfile(
        id: String,
        completion: ABICompletionCallback
    )
    external fun appDeleteProfiles(
        ids: Array<String>,
        completion: ABICompletionCallback
    )
    external fun tunnelStart(
        bundle: String,
        constants: String,
        profile: String,
        cacheDir: String,
        statusHandler: ABIConnectionStatusHandler,
        controller: AndroidTunnelController,
        completion: ABICompletionCallback
    )
    external fun tunnelStop(
        completion: ABICompletionCallback
    )

    // These are specific to Android to release JNI references
    // FIXME: Remove and let appDeinit/tunnelStop in JNI do the deallocation
    external fun appRelease()
    external fun tunnelRelease()

    override suspend fun importText(text: String, filename: String) {
        awaitCompletion { completion ->
            appImportProfileText(text, filename, completion)
        }
        appOnForeground()
    }

    override suspend fun remove(profileId: String) {
        awaitCompletion { completion ->
            appDeleteProfile(profileId, completion)
        }
    }

    override suspend fun remove(profileIds: Collection<String>) {
        awaitCompletion { completion ->
            appDeleteProfiles(profileIds.toTypedArray(), completion)
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

    companion object {
        init {
            try {
                // Name of the NDK .so without "lib" prefix or ".so"
                System.loadLibrary("passepartout_wrapper")
            } catch (e: Exception) {
                Log.e("Passepartout", e.localizedMessage ?: "")
            }
        }
    }
}

class ABIException(
    val code: Int,
    val payload: String?
) : RuntimeException("ABI call failed (code=$code): $payload")

private data class ABIResult(
    val code: Int,
    val payload: String?
) {
    fun getOrThrow() {
        if (code != 0) {
            throw ABIException(code, payload)
        }
    }
}
