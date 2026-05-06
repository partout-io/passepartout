// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import com.algoritmico.passepartout.abi.AppProfileStatus

data class ProfileItemUiState(
    val id: String,
    val isEnabled: Boolean,
    val name: String,
    val moduleSummary: String,
    val fingerprint: String,
    val status: AppProfileStatus
) {
    val statusText: String
        get() = when (status) {
            AppProfileStatus.disconnected -> "Disconnected"
            AppProfileStatus.connecting -> "Connecting"
            AppProfileStatus.connected -> "Connected"
            AppProfileStatus.disconnecting -> "Disconnecting"
        }

    val canToggle: Boolean
        get() = when (status) {
            AppProfileStatus.disconnecting -> false

            AppProfileStatus.connecting,
            AppProfileStatus.disconnected,
            AppProfileStatus.connected -> true
        }
}
