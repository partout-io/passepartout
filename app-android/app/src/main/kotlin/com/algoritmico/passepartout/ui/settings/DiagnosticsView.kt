// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.algoritmico.passepartout.business.extensions.default
import com.algoritmico.passepartout.business.extensions.issues
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.isBetaSuggestedByAndroidAPI
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.observables.LocalAppConfiguration
import com.algoritmico.passepartout.observables.LocalErrorHandler
import com.algoritmico.passepartout.observables.LocalUserPreferencesObservable
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.observables.safeOpenUri
import kotlinx.coroutines.launch

@Composable
fun DiagnosticsView(
    modifier: Modifier = Modifier
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
                DiagnosticsSection(header = "Beta") {
                    ListItem(
                        headlineContent = {
                            Text("This is a beta build")
                        }
                    )
                }
            }
        }
        item {
            DiagnosticsSection(header = "Live log")
        }
        item {
            DiagnosticsSection(header = "Preferences") {
                LogsPrivateDataRow(
                    isChecked = preferences.logsPrivateData,
                    onCheckedChange = { isChecked ->
                        userPreferencesObservable.updateLogsPrivateData(isChecked)
                    }
                )
            }
        }
        item {
            DiagnosticsSection(header = "Active profiles") {
                if (activeProfiles.isEmpty()) {
                    ListItem(
                        headlineContent = {
                            Text("No active profiles")
                        }
                    )
                } else {
                    activeProfiles.forEach {
                        ActiveProfileRow(it)
                    }
                }
            }
        }
        item {
            DiagnosticsSection {
                ReportIssueButton()
            }
        }
    }
}

@Composable
private fun DiagnosticsSection(
    header: String? = null,
    content: @Composable () -> Unit = {}
) {
    Column {
        if (header != null) {
            Text(
                text = header,
                modifier = Modifier.padding(
                    start = 16.dp,
                    top = 20.dp,
                    end = 16.dp,
                    bottom = 8.dp
                ),
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.SemiBold
            )
        }
        content()
        HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
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

    ListItem(
        headlineContent = {
            Text("Include private data")
        },
        trailingContent = {
            Switch(
                checked = isChecked,
                onCheckedChange = ::update
            )
        },
        modifier = Modifier.clickable {
            update(!isChecked)
        }
    )
}

@Composable
private fun ActiveProfileRow(
    header: AppProfileHeader
) {
    ListItem(
        headlineContent = {
            Text(header.name)
        }
    )
}

@Composable
private fun ReportIssueButton() {
    val appConfiguration = LocalAppConfiguration.current
    val uriHandler = LocalUriHandler.current
    val errorHandler = LocalErrorHandler.current
    Button(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        onClick = {
            uriHandler.safeOpenUri(
                "mailto:${appConfiguration.constants.emails.issues}",
                errorHandler
            )
        }
    ) {
        Text("Report issue")
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
