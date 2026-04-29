// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.helpers

import android.util.Log
import io.partout.jni.AndroidTunnelController

class NativeLibraryWrapper {
    external fun partoutVersion(): String
    external fun appInit(
        bundle: String,
        constants: String,
        profilesDir: String,
        cacheDir: String,
        eventHandler: ABIEventHandler
    )
    external fun appOnForeground()
    external fun appImportProfileText(
        text: String,
        name: String,
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