// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.content.Context
import android.content.pm.ApplicationInfo
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.io.Closeable

class IAPObservable(
    context: Context
) : Closeable {
    private val _isBeta = MutableStateFlow(context.isBetaSuggestedByAndroidAPI)
    val isBeta: StateFlow<Boolean> = _isBeta.asStateFlow()

    override fun close() {
        // Nothing to release until Android IAP event tracking is ported.
    }

    private val Context.isBetaSuggestedByAndroidAPI: Boolean
        get() = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
}
