// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import com.algoritmico.passepartout.context.AppLog
import androidx.compose.ui.platform.UriHandler
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.extensions.throwIfFatal
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow

class ErrorHandler(
    private val logTag: String
) {
    private val _errors = MutableSharedFlow<AppError>(
        replay = 0,
        extraBufferCapacity = 64,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )
    val errors: Flow<AppError> = _errors.asSharedFlow()

    fun report(error: Throwable) {
        report(error, "Unable to complete operation")
    }

    fun report(error: Throwable, message: String) {
        // This is a guard of last resort to rethrow CancellationException
        error.throwIfFatal()
        AppLog.e(logTag, message, error)
        _errors.tryEmit(error.asAppError)
    }
}

fun UriHandler.safeOpenUri(uri: String, handler: ErrorHandler) {
    runCatchingNonFatal {
        openUri(uri)
    }.onFailure {
        handler.report(it, "Unable to open URL ($uri)")
    }
}
