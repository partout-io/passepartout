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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.algoritmico.passepartout.business.extensions.default
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.isBetaSuggestedByAndroidAPI
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.observables.LocalErrorHandler
import com.algoritmico.passepartout.observables.LocalUserPreferencesObservable
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.ui.theme.ThemeListSection
import com.algoritmico.passepartout.ui.theme.ThemeNavigatingButton
import com.algoritmico.passepartout.ui.theme.ThemeSwitchRow
import kotlinx.coroutines.launch

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
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = 8.dp)
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
                LogsPrivateDataRow(
                    isChecked = preferences.logsPrivateData,
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

@Composable
private fun LogsPrivateDataRow(
    isChecked: Boolean,
    onCheckedChange: suspend (Boolean) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val errorHandler = LocalErrorHandler.current

    fun update(isChecked: Boolean) {
        coroutineScope.launch {
            runCatchingNonFatal {
                onCheckedChange(isChecked)
            }.onFailure {
                errorHandler.report(it)
            }
        }
    }

    ThemeSwitchRow(
        title = "Include private data",
        checked = isChecked,
        onCheckedChange = ::update
    )
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
