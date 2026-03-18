package com.algoritmico.passepartout

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.algoritmico.passepartout.abi.ABIEventCallback
import com.algoritmico.passepartout.abi.ABIEvent

class MyEventHandler() : ABIEventCallback {
    val mainHandler = Handler(Looper.getMainLooper())

    override fun onEvent(eventCtx: Any?, eventJSON: String) {
        mainHandler.post {
//            Log.i("Passepartout", ">>> Event from $eventCtx : $eventJSON")
            val event: ABIEvent = json.decodeFromString(eventJSON)
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
