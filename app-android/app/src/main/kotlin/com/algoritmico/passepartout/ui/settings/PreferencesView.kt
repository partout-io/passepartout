// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ListItem
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.observables.LocalErrorHandler
import com.algoritmico.passepartout.observables.LocalUserPreferencesObservable
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
        PreferenceSwitchRow("DNS fallback", userPreferencesObservable.dnsFallback) {
            coroutineScope.launch {
                runCatchingNonFatal {
                    userPreferencesObservable.toggleDnsFallback()
                }.onFailure {
                    errorHandler.report(it)
                }
            }
        }
        HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
        SettingsLinkRow(
            title = "Advanced",
            onClick = onAdvanced
        )
        HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
    }
}

@Composable
fun PreferenceSwitchRow(
    title: String,
    checkedFlow: Flow<Boolean>,
    onCheckedChange: (Boolean) -> Unit
) {
    val checked by checkedFlow.collectAsStateWithLifecycle(
        initialValue = false
    )
    ListItem(
        headlineContent = {
            Text(title)
        },
        supportingContent = {
            Text("Fall back to CloudFlare servers when the VPN does not provide DNS settings.")
        },
        trailingContent = {
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange
            )
        },
        modifier = Modifier.clickable {
            onCheckedChange(!checked)
        }
    )
}
