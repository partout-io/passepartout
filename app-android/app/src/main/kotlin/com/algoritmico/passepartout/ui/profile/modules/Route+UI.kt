// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import io.partout.models.Route

@Composable
internal fun Route.routeText(): String {
    val destinationText = destination ?: stringResource(R.string.global_nouns_default)
    return gateway?.let { "$destinationText → $it" } ?: destinationText
}
