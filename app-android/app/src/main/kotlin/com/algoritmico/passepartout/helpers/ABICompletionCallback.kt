package com.algoritmico.passepartout.helpers

fun interface ABICompletionCallback {
    fun onComplete(eventCtx: Any?, code: Int, errorMessage: String?)
}
