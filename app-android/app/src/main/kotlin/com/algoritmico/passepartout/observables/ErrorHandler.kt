// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.util.Log
import com.algoritmico.passepartout.injection.Tags

// FIXME: ###, Add global error handler in UI
class ErrorHandler {
    fun handle(error: Throwable) {
        Log.e(Tags.APP, "Invoke error handler", error)
    }
}