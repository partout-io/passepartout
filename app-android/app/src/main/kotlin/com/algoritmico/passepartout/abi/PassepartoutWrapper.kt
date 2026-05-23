// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi

import android.util.Log
import com.algoritmico.passepartout.Globals
import com.algoritmico.passepartout.abi.helpers.ABICompletionCallback
import com.algoritmico.passepartout.abi.helpers.ABIEventHandler
import com.algoritmico.passepartout.abi.helpers.ABIURLFetcher
import io.partout.vpn.JNITunnelController

class PassepartoutWrapper {
    external fun partoutVersion(): String
    external fun appInit(
        bundle: String,
        constants: String,
        profilesDir: String,
        cacheDir: String,
        urlFetcher: ABIURLFetcher,
        eventHandler: ABIEventHandler
    ): Int
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
    external fun appFetchProfile(
        id: String,
        completion: ABICompletionCallback
    )
    external fun tunnelStart(
        bundle: String,
        constants: String,
        profile: String,
        cacheDir: String,
        controller: JNITunnelController
    ): Int
    external fun tunnelStop(
        completion: ABICompletionCallback
    )

    companion object {
        init {
            try {
                // Name of the NDK .so without "lib" prefix or ".so"
                System.loadLibrary("passepartout_wrapper")
            } catch (e: Exception) {
                Log.e(Globals.logTag, e.localizedMessage ?: "")
            }
        }
    }
}
