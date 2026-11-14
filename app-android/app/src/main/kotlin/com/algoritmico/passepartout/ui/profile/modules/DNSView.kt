// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.Strings
import com.algoritmico.passepartout.ui.theme.ThemeDetailRow
import com.algoritmico.passepartout.ui.theme.ThemeListSectionHeader
import io.partout.models.DNSModule
import io.partout.models.DNSModuleDomainPolicy
import io.partout.models.DNSModuleProtocolTypecleartext
import io.partout.models.DNSModuleProtocolTypehttps
import io.partout.models.DNSModuleProtocolTypetls

@Composable
internal fun DNSView(module: DNSModule) {
    ThemeDetailRow(R.string.modules_dns_policy_inherits_vpn, module.inheritsVPN ?: false)
    ThemeDetailRow(R.string.modules_dns_policy_route_through_vpn,
        module.routesThroughVPN ?: stringResource(R.string.global_nouns_default))
    val canApplyDomainPolicy = module.inheritsVPN == true || module.protocolType is DNSModuleProtocolTypecleartext
    ThemeDetailRow(R.string.modules_dns_policy_use_only, canApplyDomainPolicy && module.domainPolicy == DNSModuleDomainPolicy.matchAndSearch)
    if (module.inheritsVPN == true) return
    ThemeListSectionHeader(stringResource(R.string.modules_dns_custom_settings_header))
    when (val protocol = module.protocolType) {
        is DNSModuleProtocolTypecleartext -> ThemeDetailRow(R.string.global_nouns_protocol, stringResource(R.string.entities_dns_protocol_cleartext))
        is DNSModuleProtocolTypehttps -> {
            ThemeDetailRow(R.string.global_nouns_protocol, stringResource(R.string.entities_dns_protocol_https))
            ThemeDetailRow(Strings.Unlocalized.url, protocol.url)
        }
        is DNSModuleProtocolTypetls -> {
            ThemeDetailRow(R.string.global_nouns_protocol, stringResource(R.string.entities_dns_protocol_tls))
            ThemeDetailRow(R.string.global_nouns_hostname, protocol.hostname)
        }
    }
    ThemeDetailRow(R.string.entities_dns_servers, module.servers)
    if (module.protocolType is DNSModuleProtocolTypecleartext) {
        ThemeDetailRow(R.string.entities_dns_domains, listOfNotNull(module.domainName) + module.searchDomains.orEmpty())
        ThemeDetailRow(R.string.modules_dns_domains_first_is_primary, module.domainName != null)
    }
}
