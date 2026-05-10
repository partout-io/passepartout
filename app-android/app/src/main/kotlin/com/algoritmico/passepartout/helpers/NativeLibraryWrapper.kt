package com.algoritmico.passepartout.helpers

import android.util.Log
import io.partout.jni.AndroidTunnelController

class NativeLibraryWrapper {
    val profile: AppABIProfileProtocol = AppABIProfile(this)

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