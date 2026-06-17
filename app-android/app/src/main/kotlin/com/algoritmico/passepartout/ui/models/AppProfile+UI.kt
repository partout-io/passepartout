// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.models

import com.algoritmico.passepartout.business.models.AppProfileStatus
import com.algoritmico.passepartout.business.models.ProfileTransfer

fun AppProfileStatus.statusText(): String {
    return when (this) {
        AppProfileStatus.disconnected -> "Inactive"
        AppProfileStatus.connecting -> "Activating"
        AppProfileStatus.connected -> "Active"
        AppProfileStatus.disconnecting -> "Deactivating"
    }
}

fun ProfileTransfer.transferText(): String {
    return "↓${received.formatDataUnit()} ↑${sent.formatDataUnit()}"
}
