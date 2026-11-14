// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile

import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import com.algoritmico.passepartout.ui.LocalWireGuardKeyGenerator
import com.algoritmico.passepartout.ui.profile.modules.*
import io.partout.models.*

@Composable
fun ModuleDetailView(
    module: TaggedModule,
    onOpenContent: (String, String) -> Unit,
    onCredentials: () -> Unit
) {
    Column {
        when (module) {
            is TaggedModuleDNS -> DNSView(module.value)
            is TaggedModuleIP -> IPView(module.value)
            is TaggedModuleHTTPProxy -> HTTPProxyView(module.value)
            is TaggedModuleWireGuard -> WireGuardView(module.value, onOpenContent, LocalWireGuardKeyGenerator.current)
            is TaggedModuleOpenVPN -> OpenVPNView(module.value, onOpenContent, onCredentials)
            is TaggedModuleCustom -> CustomModuleView(module.value, onOpenContent)
            is TaggedModuleOnDemand -> Unit
        }
    }
}
