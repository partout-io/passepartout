package com.algoritmico.passepartout.abi

fun interface ABIEventCallback {
    fun onEvent(eventCtx: Any?, eventJSON: String)
}
