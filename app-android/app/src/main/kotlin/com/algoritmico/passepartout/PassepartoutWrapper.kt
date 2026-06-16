// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.util.Log
import com.algoritmico.passepartout.injection.Tags
import io.partout.abi.PartoutCompletionCallback
import io.partout.vpn.JNITunnelController

class PassepartoutWrapper {
    external fun partoutInit(tag: String)
    external fun partoutVersion(): String
    external fun partoutImportProfile(
        text: String,
        name: String?,
        completion: PartoutCompletionCallback
    )
    external fun partoutDaemonStart(
        profile: String,
        cacheDir: String,
        controller: JNITunnelController
    ): Int
    external fun partoutDaemonStop(
        completion: PartoutCompletionCallback
    )

    companion object {
        private const val logTag = Tags.PARTOUT_JNI

        init {
            runCatching {
                // Name of the NDK .so without "lib" prefix or ".so"
                System.loadLibrary("passepartout_wrapper")
            }.onFailure {
                Log.e(logTag, "Unable to load JNI library: $it")
            }
        }
    }
}