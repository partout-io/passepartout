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
import com.algoritmico.passepartout.extensions.interactiveOpenVPNModule
import com.algoritmico.passepartout.extensions.withInteractiveOpenVPNCredentials
import io.partout.models.OpenVPNCredentialsOTPMethod
import io.partout.models.TaggedProfile

// FIXME: ###, Interactive, Generalize module views
@Composable
fun InteractiveOpenVPNView(
    profile: TaggedProfile,
    onDismiss: () -> Unit,
    onConnect: (TaggedProfile) -> Unit
) {
    val credentials = profile.interactiveOpenVPNModule?.credentials
    val otpMethod = credentials?.otpMethod ?: OpenVPNCredentialsOTPMethod.none
    var username by remember(profile.id) {
        mutableStateOf(credentials?.username.orEmpty())
    }
    var password by remember(profile.id) {
        mutableStateOf(credentials?.password.orEmpty())
    }
    var otp by remember(profile.id) {
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
