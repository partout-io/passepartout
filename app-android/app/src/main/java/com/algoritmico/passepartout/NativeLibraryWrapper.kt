package com.algoritmico.passepartout

import android.util.Log
import io.partout.PartoutVpnWrapper

class NativeLibraryWrapper {
    external fun partoutVersion(): String
    external fun initialize(cacheDir: String)
    external fun deinitialize()
    external fun daemonStart(profile: String, vpn: PartoutVpnWrapper): Boolean
    external fun daemonStop(): Unit

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