package com.algoritmico.passepartout.abi

fun interface ABICompletionCallback {
    fun onComplete(eventCtx: Any?, code: Int, errorMessage: String?)
}
