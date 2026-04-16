package com.algoritmico.passepartout.helpers

fun interface ConnectionStatusCallback {
    fun onStatus(statusCtx: Any?, statusJSON: String)
}