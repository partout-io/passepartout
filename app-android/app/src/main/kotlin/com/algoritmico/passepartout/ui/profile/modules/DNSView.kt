// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.Strings
import io.partout.models.DNSModule
import io.partout.models.DNSModuleDomainPolicy
import io.partout.models.DNSModuleProtocolTypecleartext
import io.partout.models.DNSModuleProtocolTypehttps
import io.partout.models.DNSModuleProtocolTypetls

@Composable
internal fun DNSView(module: DNSModule) {
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
