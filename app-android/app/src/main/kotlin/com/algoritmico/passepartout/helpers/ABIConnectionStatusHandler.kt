package com.algoritmico.passepartout.helpers

fun interface ABIConnectionStatusHandler {
    fun onStatus(onStatusJSON: String)
}