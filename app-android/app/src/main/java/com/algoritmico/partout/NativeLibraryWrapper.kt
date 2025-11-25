// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.partout
import android.util.Log

class NativeLibraryWrapper {
    external fun passepartoutExample(): Int
    external fun partoutVersion(): String
    external fun partoutInitialize(cacheDir: String): Long
    external fun partoutDeinitialize(ctx: Long)
    external fun partoutDaemonStart(ctx: Long, profile: String, vpnBuilder: VpnWrapper): Int
    external fun partoutDaemonStop(ctx: Long): Unit

    companion object {
        init {
            try {
                // Name of the NDK .so without "lib" prefix or ".so"
                System.loadLibrary("PassepartoutNative")
            } catch (e: Exception) {
                Log.e("Passepartout", e.localizedMessage ?: "")
            }
        }
    }
}