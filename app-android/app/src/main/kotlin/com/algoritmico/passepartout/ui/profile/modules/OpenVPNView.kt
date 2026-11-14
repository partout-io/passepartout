// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.Strings
import com.algoritmico.passepartout.ui.extensions.durationText
import com.algoritmico.passepartout.ui.extensions.routeText
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
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
        DetailSection(R.string.global_nouns_connection)
        DetailRow(R.string.modules_openvpn_remotes, c.remotes, onOpenContent = onOpenContent)
    }
    if (c.authUserPass == true) {
        DetailSection(R.string.global_nouns_account)
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
        DetailSection(R.string.modules_openvpn_pull)
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
        DetailSection(R.string.modules_openvpn_redirect_gateway)
        policies.forEach { ListItem(headlineContent = { Text(it) }) }
    }
    OpenVPNIPDetail(Strings.Unlocalized.ipv4, c.ipv4, c.routes4)
    OpenVPNIPDetail(Strings.Unlocalized.ipv6, c.ipv6, c.routes6)
    if (hasContent(c.dnsServers, c.dnsDomain, c.searchDomains)) {
        ThemeListSectionHeader(Strings.Unlocalized.dns)
        DetailRow(R.string.global_nouns_servers, c.dnsServers)
        DetailRow(R.string.global_nouns_domain, c.dnsDomain)
        DetailRow(R.string.entities_dns_search_domains, c.searchDomains)
    }
    if (hasContent(c.httpProxy, c.httpsProxy, c.proxyAutoConfigurationURL, c.proxyBypassDomains)) {
        ThemeListSectionHeader(Strings.Unlocalized.proxy)
        DetailRow(Strings.Unlocalized.http, c.httpProxy)
        DetailRow(Strings.Unlocalized.https, c.httpsProxy)
        DetailRow(Strings.Unlocalized.pac, c.proxyAutoConfigurationURL)
        DetailRow(R.string.entities_http_proxy_bypass_domains, c.proxyBypassDomains)
    }
    if (hasContent(c.dataCiphers, c.cipher, c.digest, c.xorMethod)) {
        DetailSection(R.string.modules_openvpn_communication)
        DetailRow(R.string.modules_openvpn_data_ciphers, c.dataCiphers?.joinToString(":") { it.value }, onOpenContent = onOpenContent)
        DetailRow(R.string.modules_openvpn_cipher, c.cipher?.value)
        DetailRow(R.string.modules_openvpn_digest, c.digest?.value)
        val xor = when (val method = c.xorMethod) {
            is OpenVPNObfuscationMethodobfuscate -> listOf(Strings.Unlocalized.OpenVPN.XOR.obfuscate.value, method.mask).joinToString(" ")
            is OpenVPNObfuscationMethodxormask -> listOf(Strings.Unlocalized.OpenVPN.XOR.xormask.value, method.mask).joinToString(" ")
            is OpenVPNObfuscationMethodreverse -> Strings.Unlocalized.OpenVPN.XOR.reverse.value
            is OpenVPNObfuscationMethodxorptrpos -> Strings.Unlocalized.OpenVPN.XOR.xorptrpos.value
            null -> null
        }
        DetailRow(Strings.Unlocalized.xor, xor, onOpenContent = onOpenContent)
    }
    if (hasContent(c.compressionFraming, c.compressionAlgorithm)) {
        DetailSection(R.string.modules_openvpn_compression)
        DetailRow(R.string.modules_openvpn_compression_framing, when (c.compressionFraming) {
            OpenVPNCompressionFraming.disabled -> stringResource(R.string.global_nouns_disabled)
            OpenVPNCompressionFraming.compLZO -> Strings.Unlocalized.OpenVPN.compLZO
            OpenVPNCompressionFraming.compress, OpenVPNCompressionFraming.compressV2 -> Strings.Unlocalized.OpenVPN.compress
            null -> null
        })
        DetailRow(R.string.modules_openvpn_compression_algorithm, when (c.compressionAlgorithm) {
            OpenVPNCompressionAlgorithm.disabled -> stringResource(R.string.global_nouns_disabled)
            OpenVPNCompressionAlgorithm.LZO -> Strings.Unlocalized.OpenVPN.lzo
            OpenVPNCompressionAlgorithm.other -> stringResource(R.string.entities_openvpn_compression_algorithm_other)
            null -> null
        })
    }
    if (hasContent(c.ca, c.clientCertificate, c.clientKey, c.tlsWrap)) {
        ThemeListSectionHeader(Strings.Unlocalized.tls)
        DetailRow(Strings.Unlocalized.ca, c.ca, onOpenContent = onOpenContent)
        DetailRow(R.string.global_nouns_certificate, c.clientCertificate, onOpenContent = onOpenContent)
        DetailRow(R.string.global_nouns_key, c.clientKey, onOpenContent = onOpenContent)
        DetailRow(R.string.modules_openvpn_tls_wrap, c.tlsWrap?.key?.data, onOpenContent = onOpenContent)
        DetailRow(R.string.modules_openvpn_eku, stringResource(if (c.checksEKU == true)
            R.string.global_nouns_enabled else R.string.global_nouns_disabled))
    }
    if (hasContent(c.keepAliveInterval, c.keepAliveTimeout)) {
        DetailSection(R.string.global_nouns_keep_alive)
        DetailRow(R.string.global_nouns_interval, c.keepAliveInterval.durationText())
        DetailRow(R.string.global_nouns_timeout, c.keepAliveTimeout.durationText())
    }
    if (hasContent(c.renegotiatesAfter, c.randomizeEndpoint, c.randomizeHostnames)) {
        DetailSection(R.string.global_nouns_other)
        DetailRow(R.string.modules_openvpn_renegotiation, c.renegotiatesAfter.durationText())
        DetailRow(R.string.modules_openvpn_randomize_endpoint, c.randomizeEndpoint?.let {
            stringResource(if (it) R.string.global_nouns_enabled else R.string.global_nouns_disabled) })
        DetailRow(R.string.modules_openvpn_randomize_hostname, c.randomizeHostnames?.let {
            stringResource(if (it) R.string.global_nouns_enabled else R.string.global_nouns_disabled) })
    }
}

@Composable
private fun OpenVPNIPDetail(title: String, ip: IPSettings?, routes: List<Route>?) {
    if (!hasContent(ip?.subnets, ip?.includedRoutes, ip?.excludedRoutes, routes)) return
    ThemeListSectionHeader(title)
    DetailRow(R.string.global_nouns_address, ip?.subnets?.firstOrNull())
    DetailRow(R.string.global_nouns_gateway, ip?.includedRoutes?.firstOrNull { it.destination == null }?.gateway)
    DetailRow(R.string.modules_ip_routes_included, (ip?.includedRoutes.orEmpty() + routes.orEmpty()).map { it.routeText() })
    DetailRow(R.string.modules_ip_routes_excluded, ip?.excludedRoutes?.map { it.routeText() })
}
