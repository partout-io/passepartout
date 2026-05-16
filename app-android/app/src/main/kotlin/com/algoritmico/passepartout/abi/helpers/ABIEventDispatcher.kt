// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi.helpers

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.algoritmico.passepartout.abi.models.Event
import com.algoritmico.passepartout.globalJsonCoder
import java.io.Closeable
import java.util.concurrent.CopyOnWriteArraySet

object ABIEventDispatcher: ABIEventHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val listeners = CopyOnWriteArraySet<(Event) -> Unit>()

    fun register(listener: (Event) -> Unit): Closeable {
        listeners.add(listener)
        return object : Closeable {
            override fun close() {
                listeners.remove(listener)
            }
        }
    }

    override fun onEvent(json: String) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            dispatchOnMain(json)
        } else {
            mainHandler.post {
                dispatchOnMain(json)
            }
        }
    }

    private fun dispatchOnMain(json: String) {
        val event: Event = globalJsonCoder.decodeFromString(json)
        listeners.forEach { listener ->
            runCatching {
                listener(event)
            }.onFailure {
                Log.e("Passepartout", "Unable to dispatch ABI callback", it)
            }
        }
    }
}
