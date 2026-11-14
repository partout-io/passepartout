// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.Strings
import com.algoritmico.passepartout.ui.extensions.hasContent
import com.algoritmico.passepartout.ui.theme.ThemeDetailRow
import com.algoritmico.passepartout.ui.theme.ThemeListSectionHeader
import io.partout.models.IPModule
import io.partout.models.IPSettings
import io.partout.models.Route

@Composable
internal fun IPView(module: IPModule) {
    IPDetail(Strings.Unlocalized.ipv4, module.ipv4)
    IPDetail(Strings.Unlocalized.ipv6, module.ipv6)
    ThemeDetailRow(Strings.Unlocalized.mtu, module.mtu)
}

@Composable
private fun IPDetail(title: String, settings: IPSettings?) {
    if (settings == null || !hasContent(settings.subnets, settings.includedRoutes, settings.excludedRoutes)) return
    ThemeListSectionHeader(title)
    ThemeDetailRow(R.string.global_nouns_address, settings.subnets)
    Routes(R.string.modules_ip_routes_included, settings.includedRoutes)
    Routes(R.string.modules_ip_routes_excluded, settings.excludedRoutes)
}

@Composable
private fun Routes(@StringRes title: Int, routes: List<Route>?) {
    if (routes.isNullOrEmpty()) return
    ThemeListSectionHeader(stringResource(title))
    routes.forEach { route ->
        ThemeDetailRow(R.string.global_nouns_destination, route.destination ?: stringResource(R.string.global_nouns_default))
        ThemeDetailRow(R.string.global_nouns_gateway, route.gateway)
    }
}
