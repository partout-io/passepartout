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
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.algoritmico.passepartout.extensions.interactiveModule
import com.algoritmico.passepartout.extensions.withInteractiveOpenVPNCredentials
import io.partout.extensions.moduleType
import io.partout.models.OpenVPNCredentialsOTPMethod
import io.partout.models.OpenVPNModule
import io.partout.models.TaggedModule
import io.partout.models.TaggedModuleOpenVPN
import io.partout.models.TaggedProfile

@Composable
fun InteractiveView(
    profile: TaggedProfile,
    onDismiss: () -> Unit,
    onConnect: (TaggedProfile) -> Unit
) {
    when (val module = profile.interactiveModule) {
        is TaggedModuleOpenVPN -> {
            InteractiveOpenVPNView(
                profile = profile,
                module = module.value,
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
    profile: TaggedProfile,
    module: OpenVPNModule,
    onDismiss: () -> Unit,
    onConnect: (TaggedProfile) -> Unit
) {
    val credentials = module.credentials
    val otpMethod = credentials?.otpMethod ?: OpenVPNCredentialsOTPMethod.none
    var username by remember(profile.id, module.id) {
        mutableStateOf(credentials?.username.orEmpty())
    }
    var password by remember(profile.id, module.id) {
        mutableStateOf(credentials?.password.orEmpty())
    }
    var otp by remember(profile.id, module.id) {
        mutableStateOf("")
    }
    val requiresOTP = otpMethod != OpenVPNCredentialsOTPMethod.none

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text("OpenVPN credentials")
        },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                if (requiresOTP) {
                    OutlinedTextField(
                        value = otp,
                        onValueChange = {
                            otp = it
                        },
                        label = {
                            Text("OTP")
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
                            Text("Username")
                        },
                        singleLine = true
                    )
                    OutlinedTextField(
                        value = password,
                        onValueChange = {
                            password = it
                        },
                        label = {
                            Text("Password")
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
                    onConnect(
                        profile.withInteractiveOpenVPNCredentials(
                            username = username,
                            password = password,
                            otp = otp
                        )
                    )
                }
            ) {
                Text("Connect")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun UnsupportedInteractiveView(
    module: TaggedModule?,
    onDismiss: () -> Unit
) {
    val moduleName = module?.moduleType?.value ?: "profile"
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text("Interactive profile")
        },
        text = {
            Text("$moduleName requires input that is not supported by this app version.")
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("OK")
            }
        }
    )
}
