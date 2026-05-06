// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.helpers

import java.io.Closeable

object ABIEventDispatcher : ABIEventHandler {
    private val dispatcher = ABIStringDispatcher()

    override fun onEvent(eventJSON: String) {
        dispatcher.dispatch(eventJSON)
    }

    fun register(listener: (String) -> Unit): Closeable =
        dispatcher.register(listener)
}
