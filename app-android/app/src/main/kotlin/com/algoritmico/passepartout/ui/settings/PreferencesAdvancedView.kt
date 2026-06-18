// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.algoritmico.passepartout.business.extensions.default
import com.algoritmico.passepartout.business.extensions.disable
import com.algoritmico.passepartout.business.extensions.enable
import com.algoritmico.passepartout.business.extensions.isAllowed
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.extensions.setAllowed
import com.algoritmico.passepartout.business.extensions.unignore
import com.algoritmico.passepartout.context.isBetaSuggestedByAndroidAPI
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.models.ConfigFlag
import com.algoritmico.passepartout.models.DistributionTarget
import com.algoritmico.passepartout.models.ExperimentalPreferences
import com.algoritmico.passepartout.observables.LocalAppConfiguration
import com.algoritmico.passepartout.observables.LocalConfigObservable
import com.algoritmico.passepartout.observables.LocalErrorHandler
import com.algoritmico.passepartout.observables.LocalUserPreferencesObservable
import kotlinx.coroutines.launch

@Composable
fun PreferencesAdvancedView(
    modifier: Modifier = Modifier
) {
    val appConfiguration = LocalAppConfiguration.current
    val isBeta = LocalContext.current.isBetaSuggestedByAndroidAPI
    val configState by LocalConfigObservable.current.state.collectAsStateWithLifecycle()
    val userPreferencesObservable = LocalUserPreferencesObservable.current
    val preferences by userPreferencesObservable.preferences.collectAsStateWithLifecycle(
        initialValue = AppPreferences.default
    )
    val coroutineScope = rememberCoroutineScope()
    val canOverride = isBeta || appConfiguration.bundle.distributionTarget == DistributionTarget.developerID
    val errorHandler = LocalErrorHandler.current

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        if (canOverride) {
            item {
                AdvancedSection(
                    footer = "Override remote configuration for this device."
                ) {
                    AdvancedFlags.forEach { flag ->
                        ConfigPreferencePickerRow(
                            flag = flag,
                            isActive = configState.isActive(flag),
                            preference = preferences.experimental.preference(forFlag = flag),
                            onPreferenceChange = { preference ->
                                coroutineScope.launch {
                                    runCatchingNonFatal {
                                        userPreferencesObservable.updateExperimentalPreferences {
                                            it.setPreference(preference, forFlag = flag)
                                        }
                                    }.onFailure {
                                        errorHandler.report(it)
                                    }
                                }
                            }
                        )
                    }
                }
            }
        } else {
            item {
                AdvancedSection(
                    header = "Allow",
                    footer = "Disable a feature to opt this device out when it is enabled remotely."
                ) {
                    AdvancedFlags.forEach { flag ->
                        ConfigFlagAllowedRow(
                            flag = flag,
                            isActive = configState.isActive(flag),
                            isAllowed = preferences.experimental.isAllowed(flag),
                            onAllowedChange = { isAllowed ->
                                coroutineScope.launch {
                                    runCatchingNonFatal {
                                        userPreferencesObservable.updateExperimentalPreferences {
                                            it.setAllowed(flag, isAllowed)
                                        }
                                    }.onFailure {
                                        errorHandler.report(it)
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun AdvancedSection(
    header: String? = null,
    footer: String? = null,
    content: @Composable () -> Unit
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
        if (footer != null) {
            Text(
                text = footer,
                modifier = Modifier.padding(
                    start = 16.dp,
                    top = 8.dp,
                    end = 16.dp,
                    bottom = 12.dp
                ),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun ConfigFlagAllowedRow(
    flag: ConfigFlag,
    isActive: Boolean,
    isAllowed: Boolean,
    onAllowedChange: (Boolean) -> Unit
) {
    ListItem(
        headlineContent = {
            Text(flag.localizedDescription)
        },
        supportingContent = {
            Text(flag.activeDescription(isActive))
        },
        trailingContent = {
            Switch(
                checked = isAllowed,
                onCheckedChange = onAllowedChange
            )
        },
        modifier = Modifier.clickable {
            onAllowedChange(!isAllowed)
        }
    )
}

@Composable
private fun ConfigPreferencePickerRow(
    flag: ConfigFlag,
    isActive: Boolean,
    preference: ConfigFlagPreference,
    onPreferenceChange: (ConfigFlagPreference) -> Unit
) {
    var isMenuExpanded by rememberSaveable {
        mutableStateOf(false)
    }

    ListItem(
        headlineContent = {
            Text(flag.localizedDescription)
        },
        supportingContent = {
            Text(flag.activeDescription(isActive))
        },
        trailingContent = {
            Box {
                TextButton(
                    onClick = {
                        isMenuExpanded = true
                    }
                ) {
                    Text(preference.localizedDescription)
                }
                DropdownMenu(
                    expanded = isMenuExpanded,
                    onDismissRequest = {
                        isMenuExpanded = false
                    }
                ) {
                    ConfigFlagPreference.entries.forEach { item ->
                        DropdownMenuItem(
                            text = {
                                Text(item.localizedDescription)
                            },
                            onClick = {
                                isMenuExpanded = false
                                onPreferenceChange(item)
                            }
                        )
                    }
                }
            }
        },
        modifier = Modifier.fillMaxWidth()
    )
}

private val AdvancedFlags = listOf(
    ConfigFlag.newProfileEncoding,
    ConfigFlag.ovpnV3,
    ConfigFlag.wgCrossV2
)

private enum class ConfigFlagPreference {
    Remote,
    Enable,
    Disable
}

private fun ExperimentalPreferences.preference(
    forFlag: ConfigFlag
): ConfigFlagPreference {
    if (ignoredConfigFlags.contains(forFlag)) {
        return ConfigFlagPreference.Disable
    }
    if (enabledConfigFlags.contains(forFlag)) {
        return ConfigFlagPreference.Enable
    }
    return ConfigFlagPreference.Remote
}

private fun ExperimentalPreferences.setPreference(
    preference: ConfigFlagPreference,
    forFlag: ConfigFlag
): ExperimentalPreferences {
    val reset = unignore(forFlag).disable(forFlag)
    return when (preference) {
        ConfigFlagPreference.Remote -> reset
        ConfigFlagPreference.Enable -> reset.enable(forFlag)
        ConfigFlagPreference.Disable -> reset.setAllowed(forFlag, isAllowed = false)
    }
}

private val ConfigFlag.localizedDescription: String
    get() = value

private fun ConfigFlag.activeDescription(
    isActive: Boolean
): String {
    return if (isActive) {
        "Enabled"
    } else {
        "Disabled"
    }
}

private val ConfigFlagPreference.localizedDescription: String
    get() {
        return when (this) {
            ConfigFlagPreference.Remote -> "Remote"
            ConfigFlagPreference.Enable -> "Enable"
            ConfigFlagPreference.Disable -> "Disable"
        }
    }
