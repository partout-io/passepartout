// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.Strings
import com.algoritmico.passepartout.ui.extensions.base64ToHex
import com.algoritmico.passepartout.ui.extensions.durationText
import com.algoritmico.passepartout.ui.extensions.hasContent
import com.algoritmico.passepartout.ui.extensions.routeText
import com.algoritmico.passepartout.ui.theme.ThemeDetailRow
import com.algoritmico.passepartout.ui.theme.ThemeListSectionHeader
import com.algoritmico.passepartout.ui.theme.ThemeNavigatingButton
import io.partout.models.*

@Composable
internal fun OpenVPNView(
    module: OpenVPNModule,
    onOpenContent: (String, String) -> Unit,
    onCredentials: () -> Unit
) {
    val c = module.configuration ?: return
    if (!c.remotes.isNullOrEmpty()) {
        ThemeListSectionHeader(stringResource(R.string.global_nouns_connection))
        ThemeDetailRow(R.string.modules_openvpn_remotes, c.remotes, onOpenContent = onOpenContent)
    }
    if (c.authUserPass == true) {
        ThemeListSectionHeader(stringResource(R.string.global_nouns_account))
        ThemeNavigatingButton(stringResource(R.string.modules_openvpn_credentials), onClick = onCredentials)
    }
    val pulled = OpenVPNPullMask.entries.filterNot { it in c.noPullMask.orEmpty() }.map {
        when (it) {
            OpenVPNPullMask.routes -> stringResource(R.string.global_nouns_routes)
            OpenVPNPullMask.dns -> Strings.Unlocalized.dns
            OpenVPNPullMask.proxy -> Strings.Unlocalized.proxy
        }
    }.sorted()
    if (pulled.isNotEmpty()) {
        ThemeListSectionHeader(stringResource(R.string.modules_openvpn_pull))
        pulled.forEach { ListItem(headlineContent = { Text(it) }) }
    }
    val policies = c.routingPolicies.orEmpty().mapNotNull {
        when (it) {
            OpenVPNRoutingPolicy.IPv4 -> Strings.Unlocalized.ipv4
            OpenVPNRoutingPolicy.IPv6 -> Strings.Unlocalized.ipv6
            else -> null
        }
    }.sorted()
    if (policies.isNotEmpty()) {
        ThemeListSectionHeader(stringResource(R.string.modules_openvpn_redirect_gateway))
        policies.forEach { ListItem(headlineContent = { Text(it) }) }
    }
    OpenVPNIPDetail(Strings.Unlocalized.ipv4, c.ipv4, c.routes4)
    OpenVPNIPDetail(Strings.Unlocalized.ipv6, c.ipv6, c.routes6)
    if (hasContent(c.dnsServers, c.dnsDomain, c.searchDomains)) {
        ThemeListSectionHeader(Strings.Unlocalized.dns)
        ThemeDetailRow(R.string.global_nouns_servers, c.dnsServers)
        ThemeDetailRow(R.string.global_nouns_domain, c.dnsDomain)
        ThemeDetailRow(R.string.entities_dns_search_domains, c.searchDomains)
    }
    if (hasContent(c.httpProxy, c.httpsProxy, c.proxyAutoConfigurationURL, c.proxyBypassDomains)) {
        ThemeListSectionHeader(Strings.Unlocalized.proxy)
        ThemeDetailRow(Strings.Unlocalized.http, c.httpProxy)
        ThemeDetailRow(Strings.Unlocalized.https, c.httpsProxy)
        ThemeDetailRow(Strings.Unlocalized.pac, c.proxyAutoConfigurationURL)
        ThemeDetailRow(R.string.entities_http_proxy_bypass_domains, c.proxyBypassDomains)
    }
    if (hasContent(c.dataCiphers, c.cipher, c.digest, c.xorMethod)) {
        ThemeListSectionHeader(stringResource(R.string.modules_openvpn_communication))
        ThemeDetailRow(R.string.modules_openvpn_data_ciphers, c.dataCiphers?.joinToString(":") { it.value }, onOpenContent = onOpenContent)
        ThemeDetailRow(R.string.modules_openvpn_cipher, c.cipher?.value)
        ThemeDetailRow(R.string.modules_openvpn_digest, c.digest?.value)
        val xor = when (val method = c.xorMethod) {
            is OpenVPNObfuscationMethodobfuscate -> method.mask.base64ToHex()?.let { "${Strings.Unlocalized.OpenVPN.XOR.obfuscate.value} $it" }
            is OpenVPNObfuscationMethodxormask -> method.mask.base64ToHex()?.let { "${Strings.Unlocalized.OpenVPN.XOR.xormask.value} $it" }
            is OpenVPNObfuscationMethodreverse -> Strings.Unlocalized.OpenVPN.XOR.reverse.value
            is OpenVPNObfuscationMethodxorptrpos -> Strings.Unlocalized.OpenVPN.XOR.xorptrpos.value
            null -> null
        }
        ThemeDetailRow(Strings.Unlocalized.xor, xor, onOpenContent = onOpenContent)
    }
    if (hasContent(c.compressionFraming, c.compressionAlgorithm)) {
        ThemeListSectionHeader(stringResource(R.string.modules_openvpn_compression))
        ThemeDetailRow(R.string.modules_openvpn_compression_framing, when (c.compressionFraming) {
            OpenVPNCompressionFraming.disabled -> stringResource(R.string.global_nouns_disabled)
            OpenVPNCompressionFraming.compLZO -> Strings.Unlocalized.OpenVPN.compLZO
            OpenVPNCompressionFraming.compress, OpenVPNCompressionFraming.compressV2 -> Strings.Unlocalized.OpenVPN.compress
            null -> null
        })
        ThemeDetailRow(R.string.modules_openvpn_compression_algorithm, when (c.compressionAlgorithm) {
            OpenVPNCompressionAlgorithm.disabled -> stringResource(R.string.global_nouns_disabled)
            OpenVPNCompressionAlgorithm.LZO -> Strings.Unlocalized.OpenVPN.lzo
            OpenVPNCompressionAlgorithm.other -> stringResource(R.string.entities_openvpn_compression_algorithm_other)
            null -> null
        })
    }
    if (hasContent(c.ca, c.clientCertificate, c.clientKey, c.tlsWrap)) {
        ThemeListSectionHeader(Strings.Unlocalized.tls)
        ThemeDetailRow(Strings.Unlocalized.ca, c.ca, onOpenContent = onOpenContent)
        ThemeDetailRow(R.string.global_nouns_certificate, c.clientCertificate, onOpenContent = onOpenContent)
        ThemeDetailRow(R.string.global_nouns_key, c.clientKey, onOpenContent = onOpenContent)
        c.tlsWrap?.let { wrap ->
            val title = stringResource(R.string.modules_openvpn_tls_wrap)
            val strategy = when (wrap.strategy) {
                OpenVPNTLSWrapStrategy.auth -> Strings.Unlocalized.OpenVPN.tlsAuth
                OpenVPNTLSWrapStrategy.crypt -> Strings.Unlocalized.OpenVPN.tlsCrypt
                OpenVPNTLSWrapStrategy.cryptV2 -> Strings.Unlocalized.OpenVPN.tlsCryptV2
            }
            wrap.key.data.base64ToHex()?.let { key ->
                ThemeNavigatingButton(title = title, trailingText = strategy,
                    onClick = { onOpenContent(title, key) })
            }
        }
        ThemeDetailRow(R.string.modules_openvpn_eku, stringResource(if (c.checksEKU == true)
            R.string.global_nouns_enabled else R.string.global_nouns_disabled))
    }
    if (hasContent(c.keepAliveInterval, c.keepAliveTimeout)) {
        ThemeListSectionHeader(stringResource(R.string.global_nouns_keep_alive))
        ThemeDetailRow(R.string.global_nouns_interval, c.keepAliveInterval.durationText())
        ThemeDetailRow(R.string.global_nouns_timeout, c.keepAliveTimeout.durationText())
    }
    if (hasContent(c.renegotiatesAfter, c.randomizeEndpoint, c.randomizeHostnames)) {
        ThemeListSectionHeader(stringResource(R.string.global_nouns_other))
        ThemeDetailRow(R.string.modules_openvpn_renegotiation, c.renegotiatesAfter.durationText())
        ThemeDetailRow(R.string.modules_openvpn_randomize_endpoint, c.randomizeEndpoint?.let {
            stringResource(if (it) R.string.global_nouns_enabled else R.string.global_nouns_disabled) })
        ThemeDetailRow(R.string.modules_openvpn_randomize_hostname, c.randomizeHostnames?.let {
            stringResource(if (it) R.string.global_nouns_enabled else R.string.global_nouns_disabled) })
    }
}

@Composable
private fun OpenVPNIPDetail(title: String, ip: IPSettings?, routes: List<Route>?) {
    if (!hasContent(ip?.subnets, ip?.includedRoutes, ip?.excludedRoutes, routes)) return
    ThemeListSectionHeader(title)
    ThemeDetailRow(R.string.global_nouns_address, ip?.subnets?.firstOrNull()?.substringBefore('/'))
    ThemeDetailRow(R.string.global_nouns_gateway, ip?.includedRoutes?.firstOrNull { it.destination == null }?.gateway)
    ThemeDetailRow(R.string.modules_ip_routes_included, (ip?.includedRoutes.orEmpty() + routes.orEmpty()).map { it.routeText() })
    ThemeDetailRow(R.string.modules_ip_routes_excluded, ip?.excludedRoutes?.map { it.routeText() })
}
