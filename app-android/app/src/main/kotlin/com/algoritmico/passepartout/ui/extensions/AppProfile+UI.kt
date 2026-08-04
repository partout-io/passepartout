// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.extensions

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.models.AppProfileStatus
import com.algoritmico.passepartout.models.ProfileTransfer

@Composable
fun AppProfileStatus.statusText(): String {
    return when (this) {
        AppProfileStatus.disconnected -> stringResource(R.string.entities_tunnel_status_inactive)
        AppProfileStatus.connecting -> stringResource(R.string.entities_tunnel_status_activating)
        AppProfileStatus.connected -> stringResource(R.string.entities_tunnel_status_active)
        AppProfileStatus.disconnecting -> stringResource(R.string.entities_tunnel_status_deactivating)
    }
}

fun ProfileTransfer.transferText(): String {
    return "↓${received.formatDataUnit()} ↑${sent.formatDataUnit()}"
}
