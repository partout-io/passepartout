// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.business.extensions.default
import com.algoritmico.passepartout.context.isBetaSuggestedByAndroidAPI
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.ui.LocalUserPreferencesObservable
import com.algoritmico.passepartout.ui.Strings
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.ui.theme.ThemeList
import com.algoritmico.passepartout.ui.theme.ThemeNavigatingButton
import com.algoritmico.passepartout.ui.theme.ThemeSwitchRow
import com.algoritmico.passepartout.ui.theme.themeListSection

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
    val liveLogHeader = stringResource(R.string.views_diagnostics_sections_live)
    val preferencesHeader = stringResource(R.string.global_nouns_preferences)
    ThemeList(modifier = modifier) {
        if (isBeta) {
            themeListSection(header = Strings.Unlocalized.beta) {
                item {
                    ListItem(
                        headlineContent = {
                            Text(Strings.Unlocalized.betaBuild)
                        }
                    )
                }
            }
        }
        themeListSection(header = liveLogHeader) {
            item {
                ThemeNavigatingButton(
                    title = stringResource(R.string.views_diagnostics_rows_app),
                    onClick = {
                        onLiveLog(SettingsCoordinatorRoute.AppLog)
                    }
                )
            }
            item {
                ThemeNavigatingButton(
                    title = stringResource(R.string.views_diagnostics_rows_tunnel),
                    onClick = {
                        onLiveLog(SettingsCoordinatorRoute.TunnelLog)
                    }
                )
            }
        }
        themeListSection(header = preferencesHeader) {
            item {
                ThemeSwitchRow(
                    title = stringResource(R.string.views_diagnostics_rows_include_private_data),
                    checked = preferences.logsPrivateData,
                    onCheckedChange = { isChecked ->
                        userPreferencesObservable.updateLogsPrivateData(isChecked)
                    }
                )
            }
        }
        themeListSection {
            item {
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
