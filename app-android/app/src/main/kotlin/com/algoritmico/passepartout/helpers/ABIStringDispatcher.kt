// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.helpers

import android.os.Handler
import android.os.Looper
import android.util.Log
import java.io.Closeable
import java.util.concurrent.CopyOnWriteArraySet

class ABIStringDispatcher {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val listeners = CopyOnWriteArraySet<(String) -> Unit>()

    fun register(listener: (String) -> Unit): Closeable {
        listeners.add(listener)
        return object : Closeable {
            override fun close() {
                listeners.remove(listener)
            }
        }
    }

    fun dispatch(value: String) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            dispatchOnMain(value)
        } else {
            mainHandler.post {
                dispatchOnMain(value)
            }
        }
    }

    private fun dispatchOnMain(value: String) {
        listeners.forEach { listener ->
            runCatching {
                listener(value)
            }.onFailure {
                Log.e("Passepartout", "Unable to dispatch ABI callback", it)
            }
        }
    }
}
