// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.extensions

import com.algoritmico.passepartout.observables.AppError
import com.algoritmico.passepartout.observables.ProfileImporterException

// FIXME: ###, AppError, Localize messages
val AppError.localizedMessage: String
    get() = when (cause) {
        is ProfileImporterException.Binary -> "Importing a binary file."
        is ProfileImporterException.Null -> "Unable to read profile content"
        else -> cause?.localizedMessage ?: code.name
    }
