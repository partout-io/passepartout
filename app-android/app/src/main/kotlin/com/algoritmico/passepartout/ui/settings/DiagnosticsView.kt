// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.algoritmico.passepartout.business.extensions.default
import com.algoritmico.passepartout.context.isBetaSuggestedByAndroidAPI
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.ui.LocalUserPreferencesObservable
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.ThemeListSection
import com.algoritmico.passepartout.ui.theme.ThemeNavigatingButton
import com.algoritmico.passepartout.ui.theme.ThemeSwitchRow

@Composable
fun DiagnosticsView(
    modifier: Modifier = Modifier,
    onLiveLog: (SettingsCoordinatorRoute) -> Unit
) {
    val context = LocalContext.current
    val isBeta = context.isBetaSuggestedByAndroidAPI
    val userPreferencesObservable = LocalUserPreferencesObservable.current
    val preferences by userPreferencesObservable.preferences.collectAsStateWithLifecycle(
        initialValue = AppPreferences.default
    )
    val theme = LocalTheme.current
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = theme.spacing.small)
    ) {
        if (isBeta) {
            item {
                ThemeListSection(header = "Beta") {
                    ListItem(
                        headlineContent = {
                            Text("This is a beta build")
                        }
                    )
                }
            }
        }
        item {
            ThemeListSection(header = "Live log") {
                ThemeNavigatingButton(
                    title = "App",
                    onClick = {
                        onLiveLog(SettingsCoordinatorRoute.AppLog)
                    }
                )
                ThemeNavigatingButton(
                    title = "Tunnel",
                    onClick = {
                        onLiveLog(SettingsCoordinatorRoute.TunnelLog)
                    }
                )
            }
        }
        item {
            ThemeListSection(header = "Preferences") {
                ThemeSwitchRow(
                    title = "Include private data",
                    checked = preferences.logsPrivateData,
                    onCheckedChange = { isChecked ->
                        userPreferencesObservable.updateLogsPrivateData(isChecked)
                    }
                )
            }
        }
        item {
            ThemeListSection {
                ReportIssueButton()
            }
        }
    }
}

private suspend fun UserPreferencesObservable.updateLogsPrivateData(
    isEnabled: Boolean
) {
    updatePreferences(
        fields = listOf(AppPreferenceKey.logsPrivateData)
    ) {
        it.copy(logsPrivateData = isEnabled)
    }
}
