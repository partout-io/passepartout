// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.Strings
import com.algoritmico.passepartout.ui.theme.ThemeDetailRow
import com.algoritmico.passepartout.ui.theme.ThemeListSectionHeader
import io.partout.models.WireGuardModule

@Composable
internal fun WireGuardView(
    module: WireGuardModule,
    onOpenContent: (String, String) -> Unit,
    derivePublicKey: (String) -> String?
) {
    val configuration = module.configuration ?: return
    val local = configuration.`interface`
    val publicKey = remember(local.privateKey, derivePublicKey) { derivePublicKey(local.privateKey) }
    ThemeListSectionHeader(stringResource(R.string.modules_wireguard_interface))
    ThemeDetailRow(R.string.global_nouns_private_key, local.privateKey, onOpenContent = onOpenContent)
    ThemeDetailRow(R.string.global_nouns_public_key, publicKey)
    ThemeDetailRow(R.string.global_nouns_addresses, local.addresses, onOpenContent = onOpenContent)
    ThemeDetailRow(Strings.Unlocalized.mtu, local.mtu)
    local.dns?.let {
        ThemeListSectionHeader(Strings.Unlocalized.dns)
        ThemeDetailRow(R.string.global_nouns_servers, it.servers, onOpenContent = onOpenContent)
        ThemeDetailRow(R.string.entities_dns_search_domains, listOfNotNull(it.domainName) + it.searchDomains.orEmpty(), onOpenContent = onOpenContent)
    }
    configuration.peers.forEachIndexed { index, peer ->
        ThemeListSectionHeader(stringResource(R.string.modules_wireguard_peer, index + 1))
        ThemeDetailRow(R.string.global_nouns_public_key, peer.publicKey, onOpenContent = onOpenContent)
        ThemeDetailRow(R.string.modules_wireguard_preshared_key, peer.preSharedKey, onOpenContent = onOpenContent)
        ThemeDetailRow(R.string.global_nouns_endpoint, peer.endpoint, onOpenContent = onOpenContent)
        ThemeDetailRow(R.string.modules_wireguard_allowed_ips, peer.allowedIPs, onOpenContent = onOpenContent)
        ThemeDetailRow(R.string.global_nouns_keep_alive, peer.keepAlive)
    }
}
