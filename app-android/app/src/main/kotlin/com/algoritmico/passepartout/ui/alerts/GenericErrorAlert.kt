// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.alerts

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.observables.AppError
import com.algoritmico.passepartout.ui.extensions.localizedMessage

@Composable
fun GenericErrorAlert(
    error: AppError,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(stringResource(R.string.global_nouns_error))
        },
        text = {
            Text(error.localizedMessage())
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.global_nouns_ok))
            }
        }
    )
}
