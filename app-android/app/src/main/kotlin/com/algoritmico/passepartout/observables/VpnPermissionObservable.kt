// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.content.Intent
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

class VpnPermissionObservable {
    private val _state = MutableStateFlow<Request?>(null)
    val state = _state.asStateFlow()

    fun request(intent: Intent) {
        _state.compareAndSet(null, Request(intent))
    }

    fun takePendingRequest(): Intent? {
        val request = _state.value ?: return null
        if (request.isLaunched) return null
        return if (_state.compareAndSet(request, request.copy(isLaunched = true))) {
            request.intent
        } else null
    }

    fun complete(): Boolean {
        val request = _state.value ?: return false
        if (!request.isLaunched) return false
        return _state.compareAndSet(request, null)
    }

    data class Request(val intent: Intent, val isLaunched: Boolean = false)
}
