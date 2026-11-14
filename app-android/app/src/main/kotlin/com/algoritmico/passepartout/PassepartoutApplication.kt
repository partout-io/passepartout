// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.app.Application
import com.algoritmico.passepartout.context.defaultAndroidConstants
import com.algoritmico.passepartout.observables.AppContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob

class PassepartoutApplication : Application() {
    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    // Lazily assembled in the UI process; the VPN service runs in its own process.
    val appContext by lazy {
        AppContext(
            defaultAndroidConstants.tags.app,
            this,
            applicationScope
        )
    }
}
