// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.alerts

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
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
import androidx.compose.ui.text.input.PasswordVisualTransformation
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.Strings
import com.algoritmico.passepartout.ui.theme.LocalTheme
import io.partout.extensions.interactiveModule
import io.partout.extensions.moduleType
import com.algoritmico.passepartout.business.models.InteractiveLogin
import io.partout.models.TaggedModule
import io.partout.models.TaggedModuleOpenVPN

@Composable
fun InteractiveView(
    login: InteractiveLogin,
    onDismiss: () -> Unit,
    onConnect: (InteractiveLogin) -> Unit
) {
    when (val module = login.original.interactiveModule) {
        is TaggedModuleOpenVPN -> {
            InteractiveOpenVPNView(
                login = login,
                onDismiss = onDismiss,
                onConnect = onConnect
            )
        }
        else -> {
            UnsupportedInteractiveView(
                module = module,
                onDismiss = onDismiss
            )
        }
    }
}

@Composable
private fun InteractiveOpenVPNView(
    login: InteractiveLogin,
    onDismiss: () -> Unit,
    onConnect: (InteractiveLogin) -> Unit
) {
    var username by remember(login) {
        mutableStateOf(login.username)
    }
    var password by remember(login) {
        mutableStateOf(if (login.needsOTP) "" else login.password)
    }
    var otp by remember(login) {
        mutableStateOf("")
    }
    val theme = LocalTheme.current
    val requiresOTP = login.needsOTP

    AlertDialog(
        onDismissRequest = onDismiss,
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(theme.spacing.medium)
            ) {
                if (requiresOTP) {
                    OutlinedTextField(
                        value = otp,
                        onValueChange = {
                            otp = it
                        },
                        label = {
                            Text(Strings.Unlocalized.otp)
                        },
                        singleLine = true,
                        visualTransformation = PasswordVisualTransformation()
                    )
                } else {
                    OutlinedTextField(
                        value = username,
                        onValueChange = {
                            username = it
                        },
                        label = {
                            Text(stringResource(R.string.global_nouns_username))
                        },
                        singleLine = true
                    )
                    OutlinedTextField(
                        value = password,
                        onValueChange = {
                            password = it
                        },
                        label = {
                            Text(stringResource(R.string.global_nouns_password))
                        },
                        singleLine = true,
                        visualTransformation = PasswordVisualTransformation()
                    )
                }
            }
        },
        confirmButton = {
            TextButton(
                enabled = if (requiresOTP) {
                    otp.isNotBlank()
                } else {
                    username.isNotBlank()
                },
                onClick = {
                    login.username = username
                    login.password = if (requiresOTP) otp else password
                    onConnect(login)
                }
            ) {
                Text(stringResource(R.string.global_actions_connect))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.global_actions_cancel))
            }
        }
    )
}

@Composable
private fun UnsupportedInteractiveView(
    module: TaggedModule?,
    onDismiss: () -> Unit
) {
    val moduleName = module?.moduleType?.value ?: stringResource(R.string.global_nouns_profile)
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(stringResource(R.string.android_alerts_interactive_unsupported_title))
        },
        text = {
            Text(stringResource(R.string.android_alerts_interactive_unsupported_message, moduleName))
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.global_nouns_ok))
            }
        }
    )
}
