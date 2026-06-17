// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable

@Composable
fun VpnPermissionDeniedAlert(
    onDismiss: () -> Unit,
    onOpenSettings: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text("VPN permission required")
        },
        text = {
            Text("Passepartout needs VPN permission to start a connection.")
        },
        confirmButton = {
            TextButton(onClick = onOpenSettings) {
                Text("Open VPN settings")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("OK")
            }
        }
    )
}
