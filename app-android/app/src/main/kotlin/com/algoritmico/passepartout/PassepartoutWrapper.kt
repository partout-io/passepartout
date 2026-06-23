// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.business.extensions.JSON
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.context.defaultAndroidConstants
import io.partout.NativeTunnelControllerJNI
import io.partout.abi.PartoutCompletionCallback
import io.partout.abi.PartoutResult
import io.partout.models.TaggedProfile

private interface PassepartoutWrapperProtocol {
    fun partoutInit(tag: String, logsPrivateData: Boolean)
    fun partoutVersion(): String
    fun partoutImportProfile(
        text: String,
        name: String?,
        completion: PartoutCompletionCallback
    )
    fun partoutDaemonStart(
        profile: String,
        cacheDir: String,
        controller: NativeTunnelControllerJNI,
        dnsFallsBack: Boolean,
        logsSnapshots: Boolean,
        minDataCountDelta: Long
    ): Int
    fun partoutDaemonStop(
        completion: PartoutCompletionCallback
    )
}

class PassepartoutWrapper: PassepartoutWrapperProtocol {
    //region Convenience overloads
    suspend fun importProfile(text: String, name: String?): TaggedProfile {
        val result = runCatchingNonFatal {
            PartoutResult.await { completion ->
                partoutImportProfile(text, name, completion)
            }
        }.getOrThrow()
        val json = result.json
        if (json == null) {
            error("partoutImportProfile() succeeded without payload")
        }
        return JSON.decode<TaggedProfile>(json)
    }
    //endregion

    //region ABI
    override external fun partoutInit(tag: String, logsPrivateData: Boolean)
    override external fun partoutVersion(): String
    override external fun partoutImportProfile(
        text: String,
        name: String?,
        completion: PartoutCompletionCallback
    )
    override external fun partoutDaemonStart(
        profile: String,
        cacheDir: String,
        controller: NativeTunnelControllerJNI,
        dnsFallsBack: Boolean,
        logsSnapshots: Boolean,
        minDataCountDelta: Long
    ): Int
    override external fun partoutDaemonStop(
        completion: PartoutCompletionCallback
    )
    //endregion

    companion object {
        init {
            // Name of the NDK .so without "lib" prefix or ".so"
            runCatchingNonFatal {
                System.loadLibrary("passepartout_wrapper")
            }.onFailure {
                AppLog.e(defaultAndroidConstants.tags.partoutJni, "Unable to load JNI library", it)
            }.getOrNull()
        }
    }
}
