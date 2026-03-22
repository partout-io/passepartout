package com.algoritmico.passepartout.helpers

fun interface ABIEventCallback {
    fun onEvent(eventCtx: Any?, eventJSON: String)
}
