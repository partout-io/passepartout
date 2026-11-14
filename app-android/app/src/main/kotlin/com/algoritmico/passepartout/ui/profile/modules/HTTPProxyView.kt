// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import androidx.compose.runtime.Composable
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.Strings
import com.algoritmico.passepartout.ui.theme.ThemeListSectionHeader
import io.partout.models.HTTPProxyModule

@Composable
internal fun HTTPProxyView(module: HTTPProxyModule) {
    ProxyEndpoint(Strings.Unlocalized.http, module.proxy)
    ProxyEndpoint(Strings.Unlocalized.https, module.secureProxy)
    if (module.pacURL != null) {
        ThemeListSectionHeader(Strings.Unlocalized.pac)
        DetailRow(Strings.Unlocalized.url, module.pacURL)
    }
    DetailRow(R.string.entities_http_proxy_bypass_domains, module.bypassDomains)
}

@Composable
private fun ProxyEndpoint(title: String, endpoint: String?) {
    if (endpoint == null) return
    ThemeListSectionHeader(title)
    val separator = endpoint.lastIndexOf(':')
    val port = endpoint.substringAfterLast(':').toIntOrNull()
    DetailRow(R.string.global_nouns_address, if (port != null && separator > 0) endpoint.substring(0, separator) else endpoint)
    DetailRow(R.string.global_nouns_port, port)
}
