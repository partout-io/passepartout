// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.extensions

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.observables.AppError
import com.algoritmico.passepartout.observables.ProfileImporterException
import com.algoritmico.passepartout.observables.asAppError

@Composable
fun AppError.localizedMessage(): String {
    var msg = when (cause) {
        is ProfileImporterException.Binary -> stringResource(R.string.android_errors_profile_importer_binary)
        is ProfileImporterException.Failure -> stringResource(R.string.android_errors_profile_importer_failure)
        is ProfileImporterException.Null -> stringResource(R.string.android_errors_profile_importer_empty)
        else -> cause?.asAppError?.localizedMessage() ?: code.name
    }
    val underlyingCause = cause?.cause
    underlyingCause?.asAppError?.let {
        msg += " "
        msg += it.localizedMessage()
    }
    return msg
}
