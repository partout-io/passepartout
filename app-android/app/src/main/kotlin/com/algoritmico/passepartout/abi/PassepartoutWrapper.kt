// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi

import android.util.Log
import com.algoritmico.passepartout.abi.helpers.ABICompletionCallback
import com.algoritmico.passepartout.abi.helpers.ABIConnectionStatusHandler
import com.algoritmico.passepartout.abi.helpers.ABIEventHandler
import io.partout.abi.TaggedProfile
import io.partout.jni.AndroidTunnel
import io.partout.jni.AndroidTunnelController

class PassepartoutWrapper {
    external fun partoutVersion(): String
    external fun appInit(
        bundle: String,
        constants: String,
        profilesDir: String,
        cacheDir: String,
        tunnel: AndroidTunnel,
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
    external fun appConnect(
        profile: String,
        completion: ABICompletionCallback
    )
    external fun appDisconnect(
        profileId: String,
        completion: ABICompletionCallback
    )
    external fun tunnelStart(
        bundle: String,
        constants: String,
        profile: String,
        cacheDir: String,
        controller: AndroidTunnelController,
        statusHandler: ABIConnectionStatusHandler
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
                Log.e("Passepartout", e.localizedMessage ?: "")
            }
        }
    }
}
