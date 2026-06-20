// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.algoritmico.passepartout.ui.LocalUserPreferencesObservable
import com.algoritmico.passepartout.ui.theme.ThemeListSection
import com.algoritmico.passepartout.ui.theme.ThemeSwitchRow

@Composable
fun PreferencesView(
    modifier: Modifier = Modifier,
    onAdvanced: () -> Unit
) {
    val userPreferencesObservable = LocalUserPreferencesObservable.current
    Column(
        modifier = modifier.fillMaxSize()
    ) {
        ThemeListSection {
            ThemeSwitchRow(
                title = "DNS fallback",
                supportingText = "Fall back to CloudFlare servers when the VPN does not provide DNS settings.",
                checkedFlow = userPreferencesObservable.dnsFallback,
                onCheckedChange = {
                    userPreferencesObservable.toggleDnsFallback()
                }
            )
            // Hide "Advanced" because there are no actionable config flags
//            ThemeNavigatingButton(
//                title = "Advanced",
//                onClick = onAdvanced
//            )
        }
    }
}
