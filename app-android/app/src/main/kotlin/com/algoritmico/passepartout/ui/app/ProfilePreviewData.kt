// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.app

import com.algoritmico.passepartout.models.AppProfileHeader
import io.partout.models.ModuleType

internal val PreviewProfileHeaders = listOf(
    previewProfileHeader(
        id = "home",
        name = "Home VPN",
        moduleType = ModuleType.WireGuard
    ),
    previewProfileHeader(
        id = "office",
        name = "Office",
        moduleType = ModuleType.OpenVPN
    ),
    previewProfileHeader(
        id = "broken",
        name = "Staging",
        moduleType = ModuleType.OpenVPN
    )
)

private fun previewProfileHeader(
    id: String,
    name: String,
    moduleType: ModuleType
): AppProfileHeader {
    return AppProfileHeader(
        id = id,
        name = name,
        moduleTypes = listOf(moduleType),
        secondaryModuleTypes = emptyList(),
        fingerprint = id,
        sharingFlags = emptyList(),
        requiredFeatures = emptyList(),
        primaryModuleType = moduleType
    )
}
