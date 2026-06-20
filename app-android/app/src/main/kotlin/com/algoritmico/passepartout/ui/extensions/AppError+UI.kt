// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.extensions

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.models.AppErrorCode
import com.algoritmico.passepartout.observables.AppError
import com.algoritmico.passepartout.observables.ProfileImporterException
import com.algoritmico.passepartout.observables.asAppError

@Composable
fun AppError.localizedMessage(): String {
    var msg = when (cause) {
        is ProfileImporterException.Binary -> stringResource(R.string.errors_app_import_binary)
        is ProfileImporterException.Failure -> stringResource(R.string.errors_app_import_generic)
        is ProfileImporterException.Null -> stringResource(R.string.android_errors_profile_importer_empty)
        else -> cause?.asAppError?.localizedMessage() ?: code.localizedMessage()
    }
    val underlyingCause = cause?.cause
    underlyingCause?.asAppError?.let {
        msg += " "
        msg += it.localizedMessage()
    }
    return msg
}

@Composable
private fun AppErrorCode.localizedMessage(): String {
    return when (this) {
        AppErrorCode.binaryFile -> stringResource(R.string.errors_app_import_binary)
        AppErrorCode.importError -> stringResource(R.string.errors_app_import_generic)
        else -> name
    }
}
