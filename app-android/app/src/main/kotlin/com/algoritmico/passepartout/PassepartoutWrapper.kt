// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.business.extensions.JSON
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.context.defaultAndroidConstants
import io.partout.NativeTunnelControllerJNI
import io.partout.abi.PartoutResult
import io.partout.models.TaggedProfile

interface PassepartoutWrapperProtocol {
    fun partoutInit(tag: String, logsPrivateData: Boolean)
    fun partoutVersion(): String
    fun partoutImportProfile(
        text: String,
        name: String?
    ): String?
    fun partoutDaemonStart(
        profile: String,
        cacheDir: String,
        controller: NativeTunnelControllerJNI,
        minDataCountDelta: Long
    ): Int
    fun partoutDaemonStop()
}

class PassepartoutWrapper: PassepartoutWrapperProtocol {
    //region Convenience overloads
    suspend fun importProfile(text: String, name: String?): TaggedProfile {
        val result = runCatchingNonFatal {
            PartoutResult.await { completion ->
                val json = partoutImportProfile(text, name)
                val code = if (json != null) 0 else -1
                completion.onComplete(code, json)
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
        name: String?
    ): String?
    override external fun partoutDaemonStart(
        profile: String,
        cacheDir: String,
        controller: NativeTunnelControllerJNI,
        minDataCountDelta: Long
    ): Int
    override external fun partoutDaemonStop()
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
