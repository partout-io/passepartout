// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.observables.LocalErrorHandler
import com.algoritmico.passepartout.observables.LocalUserPreferencesObservable
import com.algoritmico.passepartout.ui.theme.ThemeListSection
import com.algoritmico.passepartout.ui.theme.ThemeSwitchRow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

@Composable
fun PreferencesView(
    modifier: Modifier = Modifier,
    onAdvanced: () -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val errorHandler = LocalErrorHandler.current
    val userPreferencesObservable = LocalUserPreferencesObservable.current
    Column(
        modifier = modifier.fillMaxSize()
    ) {
        ThemeListSection {
            PreferenceSwitchRow("DNS fallback", userPreferencesObservable.dnsFallback) {
                coroutineScope.launch {
                    runCatchingNonFatal {
                        userPreferencesObservable.toggleDnsFallback()
                    }.onFailure {
                        errorHandler.report(it)
                    }
                }
            }
            // Hide "Advanced" because there are no actionable config flags
//            ThemeNavigatingButton(
//                title = "Advanced",
//                onClick = onAdvanced
//            )
        }
    }
}

@Composable
private fun PreferenceSwitchRow(
    title: String,
    checkedFlow: Flow<Boolean>,
    onCheckedChange: (Boolean) -> Unit
) {
    val checked by checkedFlow.collectAsStateWithLifecycle(
        initialValue = false
    )
    ThemeSwitchRow(
        title = title,
        supportingText = "Fall back to CloudFlare servers when the VPN does not provide DNS settings.",
        checked = checked,
        onCheckedChange = onCheckedChange
    )
}
