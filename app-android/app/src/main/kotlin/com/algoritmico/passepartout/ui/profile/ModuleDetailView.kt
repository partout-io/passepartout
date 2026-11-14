// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0
package com.algoritmico.passepartout.ui.profile

import android.icu.text.MeasureFormat
import android.icu.util.Measure
import android.icu.util.MeasureUnit
import androidx.annotation.StringRes
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.Strings
import com.algoritmico.passepartout.ui.theme.ThemeListSectionHeader
import com.algoritmico.passepartout.ui.theme.ThemeNavigatingButton
import io.partout.models.*

@Composable
fun ModuleDetailView(
    module: TaggedModule,
    onOpenContent: (String, String) -> Unit,
    onCredentials: () -> Unit
) {
    Column {
        when (module) {
            is TaggedModuleDNS -> DNSDetail(module.value)
            is TaggedModuleIP -> {
                IPDetail(Strings.Unlocalized.ipv4, module.value.ipv4)
                IPDetail(Strings.Unlocalized.ipv6, module.value.ipv6)
                DetailRow(Strings.Unlocalized.mtu, module.value.mtu)
            }
            is TaggedModuleHTTPProxy -> ProxyDetail(module.value)
            is TaggedModuleWireGuard -> WireGuardDetail(module.value, onOpenContent)
            is TaggedModuleOpenVPN -> OpenVPNDetail(module.value, onOpenContent, onCredentials)
            is TaggedModuleCustom -> DetailRow(R.string.global_nouns_configuration, module.value.json.toString(), onOpenContent = onOpenContent)
            is TaggedModuleOnDemand -> Unit
        }
    }
}

@Composable
private fun DNSDetail(module: DNSModule) {
    DetailRow(R.string.modules_dns_policy_inherits_vpn, module.inheritsVPN ?: false)
    DetailRow(R.string.modules_dns_policy_route_through_vpn,
        module.routesThroughVPN?.let { stringResource(if (it) R.string.global_nouns_yes else R.string.global_nouns_no) }
            ?: stringResource(R.string.global_nouns_default))
    val canApplyDomainPolicy = module.inheritsVPN == true || module.protocolType is DNSModuleProtocolTypecleartext
    DetailRow(R.string.modules_dns_policy_use_only, canApplyDomainPolicy && module.domainPolicy == DNSModuleDomainPolicy.matchAndSearch)
    if (module.inheritsVPN == true) return
    DetailSection(R.string.modules_dns_custom_settings_header)
    when (val protocol = module.protocolType) {
        is DNSModuleProtocolTypecleartext -> DetailRow(R.string.global_nouns_protocol, stringResource(R.string.entities_dns_protocol_cleartext))
        is DNSModuleProtocolTypehttps -> {
            DetailRow(R.string.global_nouns_protocol, stringResource(R.string.entities_dns_protocol_https))
            DetailRow(Strings.Unlocalized.url, protocol.url)
        }
        is DNSModuleProtocolTypetls -> {
            DetailRow(R.string.global_nouns_protocol, stringResource(R.string.entities_dns_protocol_tls))
            DetailRow(R.string.global_nouns_hostname, protocol.hostname)
        }
    }
    DetailRow(R.string.entities_dns_servers, module.servers)
    if (module.protocolType is DNSModuleProtocolTypecleartext) {
        DetailRow(R.string.entities_dns_domains, listOfNotNull(module.domainName) + module.searchDomains.orEmpty())
        DetailRow(R.string.modules_dns_domains_first_is_primary, module.domainName != null)
    }
}

@Composable
private fun ProxyDetail(module: HTTPProxyModule) {
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

@Composable
private fun WireGuardDetail(module: WireGuardModule, onOpenContent: (String, String) -> Unit) {
    val configuration = module.configuration ?: return
    val local = configuration.`interface`
    DetailSection(R.string.modules_wireguard_interface)
    DetailRow(R.string.global_nouns_private_key, local.privateKey, onOpenContent = onOpenContent)
    DetailRow(R.string.global_nouns_addresses, local.addresses, onOpenContent = onOpenContent)
    DetailRow(Strings.Unlocalized.mtu, local.mtu)
    local.dns?.let {
        ThemeListSectionHeader(Strings.Unlocalized.dns)
        DetailRow(R.string.global_nouns_servers, it.servers, onOpenContent = onOpenContent)
        DetailRow(R.string.entities_dns_search_domains, listOfNotNull(it.domainName) + it.searchDomains.orEmpty(), onOpenContent = onOpenContent)
    }
    configuration.peers.forEachIndexed { index, peer ->
        ThemeListSectionHeader(stringResource(R.string.modules_wireguard_peer, index + 1))
        DetailRow(R.string.global_nouns_public_key, peer.publicKey, onOpenContent = onOpenContent)
        DetailRow(R.string.modules_wireguard_preshared_key, peer.preSharedKey, onOpenContent = onOpenContent)
        DetailRow(R.string.global_nouns_endpoint, peer.endpoint, onOpenContent = onOpenContent)
        DetailRow(R.string.modules_wireguard_allowed_ips, peer.allowedIPs, onOpenContent = onOpenContent)
        DetailRow(R.string.global_nouns_keep_alive, peer.keepAlive)
    }
}

@Composable
private fun OpenVPNDetail(
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
        DetailRow(R.string.global_nouns_interval, durationText(c.keepAliveInterval))
        DetailRow(R.string.global_nouns_timeout, durationText(c.keepAliveTimeout))
    }
    if (hasContent(c.renegotiatesAfter, c.randomizeEndpoint, c.randomizeHostnames)) {
        DetailSection(R.string.global_nouns_other)
        DetailRow(R.string.modules_openvpn_renegotiation, durationText(c.renegotiatesAfter))
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
    DetailRow(R.string.modules_ip_routes_included, (ip?.includedRoutes.orEmpty() + routes.orEmpty()).map { routeText(it) })
    DetailRow(R.string.modules_ip_routes_excluded, ip?.excludedRoutes?.map { routeText(it) })
}

@Composable
private fun routeText(route: Route): String {
    val destination = route.destination ?: stringResource(R.string.global_nouns_default)
    return route.gateway?.let { "$destination → $it" } ?: destination
}

@Composable
private fun DetailSection(@StringRes title: Int) {
    ThemeListSectionHeader(stringResource(title))
}

@Composable
private fun DetailRow(@StringRes title: Int, value: Any?, onOpenContent: ((String, String) -> Unit)? = null) {
    DetailRow(stringResource(title), value, onOpenContent)
}

@Composable
private fun DetailRow(label: String, value: Any?, onOpenContent: ((String, String) -> Unit)? = null) {
    if (value == null) return
    val text = when (value) {
        is Boolean -> stringResource(if (value) R.string.global_nouns_yes else R.string.global_nouns_no)
        is List<*> -> value.joinToString("\n")
        else -> value.toString()
    }
    if (text.isEmpty()) return
    if (onOpenContent != null) {
        ThemeNavigatingButton(title = label, onClick = { onOpenContent(label, text) })
        return
    }
    ListItem(
        headlineContent = { Text(label) },
        supportingContent = { SelectionContainer { Text(text) } }
    )
}

private fun hasContent(vararg values: Any?): Boolean = values.any { value ->
    when (value) {
        null -> false
        is Collection<*> -> value.isNotEmpty()
        is String -> value.isNotEmpty()
        else -> true
    }
}

@Composable
private fun durationText(seconds: Double?): String? {
    if (seconds == null) return null
    if (seconds <= 0) return stringResource(R.string.global_nouns_disabled)
    val total = seconds.toLong()
    val hours = total / 3600
    val minutes = total % 3600 / 60
    val remainder = total % 60
    val measures = listOfNotNull(
        hours.takeIf { it > 0 }?.let { Measure(it, MeasureUnit.HOUR) },
        minutes.takeIf { it > 0 }?.let { Measure(it, MeasureUnit.MINUTE) },
        remainder.takeIf { it > 0 || total == 0L }?.let { Measure(it, MeasureUnit.SECOND) }
    )
    val locale = LocalConfiguration.current.locales[0]
    return MeasureFormat.getInstance(locale, MeasureFormat.FormatWidth.SHORT)
        .formatMeasures(*measures.toTypedArray())
}
