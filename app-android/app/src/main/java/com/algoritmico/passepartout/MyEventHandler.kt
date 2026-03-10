package com.algoritmico.passepartout

import android.util.Log

class MyEventHandler() : ABIEventCallback {
    override fun onEvent(eventCtx: Any, eventJSON: String) {
        Log.i("Passepartout", ">>> Event from $eventCtx : $eventJSON")
    }
}
