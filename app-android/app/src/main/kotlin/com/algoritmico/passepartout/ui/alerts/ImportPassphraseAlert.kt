// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.alerts

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.theme.LocalTheme

@Composable
fun ImportPassphraseAlert(
    filename: String,
    onDecrypt: (String) -> Unit,
    onDismiss: () -> Unit
) {
    var passphrase by remember(filename) { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.views_app_toolbar_import_file)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(LocalTheme.current.spacing.medium)) {
                Text(stringResource(R.string.alerts_import_passphrase_message, filename))
                OutlinedTextField(
                    value = passphrase,
                    onValueChange = { passphrase = it },
                    label = { Text(stringResource(R.string.placeholders_secret)) },
                    singleLine = true,
                    visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password)
                )
            }
        },
        confirmButton = {
            TextButton(onClick = {
                val submitted = passphrase
                passphrase = ""
                onDecrypt(submitted)
            }) {
                Text(stringResource(R.string.alerts_import_passphrase_ok))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.global_actions_cancel))
            }
        }
    )
}
