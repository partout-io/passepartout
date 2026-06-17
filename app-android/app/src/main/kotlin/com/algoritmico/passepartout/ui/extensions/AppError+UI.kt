// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.extensions

import com.algoritmico.passepartout.ui.observables.AppError

// FIXME: ###, AppError, Localize messages
val AppError.localizedMessage: String
    get() = cause?.localizedMessage ?: code.name