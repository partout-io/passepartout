package com.algoritmico.passepartout

fun interface ABIEventCallback {
    fun onEvent(eventCtx: Any, eventJSON: String)
}
