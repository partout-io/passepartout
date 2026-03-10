package com.algoritmico.passepartout

import android.util.Log

fun interface ABIEventCallback {
    fun onEvent(eventCtx: Any, eventJSON: String)
}

class MyCallback(val activity: MainActivity) : ABIEventCallback {
    override fun onEvent(eventCtx: Any, eventJSON: String) {
        Log.i("Passepartout", ">>> Event from $eventCtx : $eventJSON")
    }
}
