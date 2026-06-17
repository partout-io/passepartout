// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.models

import com.algoritmico.passepartout.observables.AppError

// FIXME: ###, AppError, Localize messages
val AppError.localizedMessage: String
    get() = cause?.localizedMessage ?: code.name