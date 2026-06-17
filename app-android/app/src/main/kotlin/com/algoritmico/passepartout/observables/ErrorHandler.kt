// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.util.Log
import com.algoritmico.passepartout.injection.Tags
import com.algoritmico.passepartout.injection.throwIfCancellation
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow

object ErrorHandler {
    private val _errors = MutableSharedFlow<AppError>(
        replay = 0,
        extraBufferCapacity = 64,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )
    val errors: Flow<AppError> = _errors.asSharedFlow()

    fun report(error: Throwable) {
        // This is a guard of last resort to rethrow CancellationException
        error.throwIfCancellation()
        Log.e(Tags.APP, "Invoke error handler", error)
        _errors.tryEmit(error.asAppError)
    }
}
