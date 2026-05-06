// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.helpers

import java.io.Closeable

object ABIConnectionStatusDispatcher : ABIConnectionStatusHandler {
    private val dispatcher = ABIStringDispatcher()

    override fun onStatus(onStatusJSON: String) {
        dispatcher.dispatch(onStatusJSON)
    }

    fun register(listener: (String) -> Unit): Closeable =
        dispatcher.register(listener)
}
