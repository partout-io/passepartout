package com.algoritmico.passepartout.abi

import android.util.Log
import io.partout.jni.PartoutVpnWrapper

class NativeLibraryWrapper {
    external fun partoutVersion(): String
    external fun appInit(
        bundle: String,
        constants: String,
        profilesDir: String,
        cacheDir: String,
        eventContext: Any,
        eventCallback: ABIEventCallback
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
        vpn: PartoutVpnWrapper
    )
    external fun tunnelStop(): Unit

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