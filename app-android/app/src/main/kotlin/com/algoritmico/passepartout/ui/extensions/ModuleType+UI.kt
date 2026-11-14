// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0
package com.algoritmico.passepartout.ui.extensions

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.Strings
import io.partout.models.ModuleType

@Composable
fun ModuleType?.titleText(): String = when (this) {
    ModuleType.OpenVPN -> Strings.Unlocalized.openVPN
    ModuleType.WireGuard -> Strings.Unlocalized.wireGuard
    ModuleType.DNS -> Strings.Unlocalized.dns
    ModuleType.HTTPProxy -> Strings.Unlocalized.httpProxy
    ModuleType.IP -> stringResource(R.string.global_nouns_routing)
    ModuleType.OnDemand -> stringResource(R.string.global_nouns_on_demand)
    ModuleType.Provider -> stringResource(R.string.global_nouns_provider)
    null -> stringResource(R.string.global_nouns_unknown)
    else -> toString()
}
