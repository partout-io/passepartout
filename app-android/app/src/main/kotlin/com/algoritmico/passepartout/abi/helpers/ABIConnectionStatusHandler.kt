package com.algoritmico.passepartout.abi.helpers

fun interface ABIConnectionStatusHandler {
    fun onStatus(onStatusJSON: String)
}