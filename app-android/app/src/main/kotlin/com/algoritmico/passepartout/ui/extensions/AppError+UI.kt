// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.extensions

import com.algoritmico.passepartout.observables.AppError
import com.algoritmico.passepartout.observables.ProfileImporterException
import com.algoritmico.passepartout.observables.asAppError

// FIXME: ###, AppError, Localize messages
val AppError.localizedMessage: String
    get() {
        var msg = when (cause) {
            is ProfileImporterException.Binary -> "Importing a binary file."
            is ProfileImporterException.Failure -> "Unable to import profile."
            is ProfileImporterException.Null -> "Unable to read profile content."
            else -> cause?.asAppError?.localizedMessage ?: code.name
        }
        val underlyingCause = cause?.cause
        underlyingCause?.asAppError?.let {
            msg += " "
            msg += it.localizedMessage
        }
        return msg
    }
