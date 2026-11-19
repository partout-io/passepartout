// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import com.algoritmico.passepartout.business.strategy.WireGuardKeyGenerator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.Strings
import com.algoritmico.passepartout.ui.extensions.hasContent
import com.algoritmico.passepartout.ui.theme.ThemeTextField
import com.algoritmico.passepartout.ui.theme.ThemeDetailRow
import com.algoritmico.passepartout.ui.theme.ThemeListSectionHeader
import io.partout.models.WireGuardModule

@Composable
internal fun WireGuardView(
    module: WireGuardModule,
    onOpenContent: (String, String) -> Unit,
    keyGenerator: WireGuardKeyGenerator
) {
    val configuration = module.configuration ?: return
    val local = configuration.`interface`
    val publicKey = remember(local.privateKey, keyGenerator) { keyGenerator.publicKey(local.privateKey) }
    ThemeListSectionHeader(stringResource(R.string.modules_wireguard_interface))
    ThemeTextField(
        value = local.privateKey,
        onValueChange = {},
        label = stringResource(R.string.global_nouns_private_key),
        secure = true,
        readOnly = true
    )
    ThemeTextField(
        value = publicKey.orEmpty(),
        onValueChange = {},
        label = stringResource(R.string.global_nouns_public_key),
        readOnly = true
    )
    ThemeDetailRow(R.string.global_nouns_addresses, local.addresses, onOpenContent = onOpenContent)
    ThemeDetailRow(Strings.Unlocalized.mtu, local.mtu)
    local.dns?.takeIf { hasContent(it.servers, it.domainName, it.searchDomains) }?.let {
        ThemeListSectionHeader(Strings.Unlocalized.dns)
        ThemeDetailRow(R.string.global_nouns_servers, it.servers, onOpenContent = onOpenContent)
        ThemeDetailRow(R.string.entities_dns_search_domains, listOfNotNull(it.domainName) + it.searchDomains.orEmpty(), onOpenContent = onOpenContent)
    }
    configuration.peers.forEachIndexed { index, peer ->
        ThemeListSectionHeader(stringResource(R.string.modules_wireguard_peer, index + 1))
        ThemeTextField(
            value = peer.publicKey,
            onValueChange = {},
            label = stringResource(R.string.global_nouns_public_key),
            readOnly = true
        )
        ThemeTextField(
            value = peer.preSharedKey.orEmpty(),
            onValueChange = {},
            label = stringResource(R.string.modules_wireguard_preshared_key),
            secure = true,
            readOnly = true
        )
        ThemeDetailRow(R.string.global_nouns_endpoint, peer.endpoint, onOpenContent = onOpenContent)
        ThemeDetailRow(R.string.modules_wireguard_allowed_ips, peer.allowedIPs, onOpenContent = onOpenContent)
        ThemeDetailRow(R.string.global_nouns_keep_alive, peer.keepAlive)
    }
}
