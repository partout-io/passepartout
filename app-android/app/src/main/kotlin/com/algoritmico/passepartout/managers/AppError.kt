// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.managers

import com.algoritmico.passepartout.models.AppErrorCode

data class AppError(
    val code: AppErrorCode,
    val cause: Throwable? = null
)

// FIXME: ###, Map known errors to AppError
val Throwable.asAppError: AppError
    get() = AppError(AppErrorCode.other, this)

// FIXME: ###, Localize error messages
val AppError.localizedMessage: String
    get() = cause?.localizedMessage ?: code.name