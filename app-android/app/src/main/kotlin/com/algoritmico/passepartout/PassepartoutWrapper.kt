// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.Tags
import io.partout.NativeTunnelControllerJNI
import io.partout.abi.PartoutCompletionCallback

interface PassepartoutWrapperProtocol {
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
        controller: NativeTunnelControllerJNI
    ): Int
    fun partoutDaemonStop(
        completion: PartoutCompletionCallback
    )
}

class PassepartoutWrapper: PassepartoutWrapperProtocol {
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
        controller: NativeTunnelControllerJNI
    ): Int
    override external fun partoutDaemonStop(
        completion: PartoutCompletionCallback
    )

    companion object {
        init {
            // Name of the NDK .so without "lib" prefix or ".so"
            runCatchingNonFatal {
                System.loadLibrary("passepartout_wrapper")
            }.onFailure {
                AppLog.e(Tags.PARTOUT_JNI, "Unable to load JNI library", it)
            }.getOrNull()
        }
    }
}
