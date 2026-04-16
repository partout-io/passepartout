// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.algoritmico.passepartout.abi.Event
import com.algoritmico.passepartout.helpers.ABIEventCallback

class MyEventHandler() : ABIEventCallback {
    val mainHandler = Handler(Looper.getMainLooper())

    override fun onEvent(eventCtx: Any?, eventJSON: String) {
        mainHandler.post {
//            Log.i("Passepartout", ">>> Event from $eventCtx : $eventJSON")
            val event: Event = globalJsonCoder.decodeFromString(eventJSON)
            Log.i("Passepartout", ">>> MyEventHandler: $event")
//            val event2: EventPayload = json.decodeFromString("""
//{
//  "type": "ProfileEvent_Ready"
//}
//            """.trimIndent())
//            Log.i("Passepartout", ">>> Event (object) : $event2")
        }
    }
}
