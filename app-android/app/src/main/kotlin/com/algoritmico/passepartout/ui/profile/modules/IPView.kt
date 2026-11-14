// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.Strings
import androidx.annotation.StringRes
import com.algoritmico.passepartout.ui.theme.ThemeListSectionHeader
import io.partout.models.IPModule
import io.partout.models.IPSettings
import io.partout.models.Route

@Composable
internal fun IPView(module: IPModule) {
    IPDetail(Strings.Unlocalized.ipv4, module.ipv4)
    IPDetail(Strings.Unlocalized.ipv6, module.ipv6)
    DetailRow(Strings.Unlocalized.mtu, module.mtu)
}

@Composable
private fun IPDetail(title: String, settings: IPSettings?) {
    if (settings == null || !hasContent(settings.subnets, settings.includedRoutes, settings.excludedRoutes)) return
    ThemeListSectionHeader(title)
    DetailRow(R.string.global_nouns_address, settings.subnets)
    Routes(R.string.modules_ip_routes_included, settings.includedRoutes)
    Routes(R.string.modules_ip_routes_excluded, settings.excludedRoutes)
}

@Composable
private fun Routes(@StringRes title: Int, routes: List<Route>?) {
    if (routes.isNullOrEmpty()) return
    DetailSection(title)
    routes.forEach { route ->
        DetailRow(R.string.global_nouns_destination, route.destination ?: stringResource(R.string.global_nouns_default))
        DetailRow(R.string.global_nouns_gateway, route.gateway)
    }
}
