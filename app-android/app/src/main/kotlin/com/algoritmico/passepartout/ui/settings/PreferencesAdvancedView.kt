// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ListItem
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
import com.algoritmico.passepartout.observables.ConfigObservable
import com.algoritmico.passepartout.observables.ErrorHandler
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.ThemeListSection
import com.algoritmico.passepartout.ui.theme.ThemeSwitchRow
import kotlinx.coroutines.CoroutineScope
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

    fun updateExperimentalPreferences(
        transform: (ExperimentalPreferences) -> ExperimentalPreferences
    ) {
        userPreferencesObservable.updateExperimentalPreferencesSafely(
            coroutineScope = coroutineScope,
            errorHandler = errorHandler,
            transform = transform
        )
    }

    AdvancedPreferencesContent(
        modifier = modifier,
        canOverride = canOverride,
        configState = configState,
        preferences = preferences.experimental,
        onPreferenceChange = { flag, preference ->
            updateExperimentalPreferences {
                it.setPreference(preference, forFlag = flag)
            }
        },
        onAllowedChange = { flag, isAllowed ->
            userPreferencesObservable.updateExperimentalPreferences {
                it.setAllowed(flag, isAllowed)
            }
        }
    )
}

@Composable
private fun AdvancedPreferencesContent(
    modifier: Modifier,
    canOverride: Boolean,
    configState: ConfigObservable.State,
    preferences: ExperimentalPreferences,
    onPreferenceChange: (ConfigFlag, ConfigFlagPreference) -> Unit,
    onAllowedChange: suspend (ConfigFlag, Boolean) -> Unit
) {
    val theme = LocalTheme.current

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = theme.spacing.small)
    ) {
        item {
            if (canOverride) {
                ConfigOverrideSection(
                    configState = configState,
                    preferences = preferences,
                    onPreferenceChange = onPreferenceChange
                )
            } else {
                ConfigAllowSection(
                    configState = configState,
                    preferences = preferences,
                    onAllowedChange = onAllowedChange
                )
            }
        }
    }
}

@Composable
private fun ConfigOverrideSection(
    configState: ConfigObservable.State,
    preferences: ExperimentalPreferences,
    onPreferenceChange: (ConfigFlag, ConfigFlagPreference) -> Unit
) {
    ThemeListSection(
        footer = "Override remote configuration for this device."
    ) {
        AdvancedFlags.forEach { flag ->
            ConfigPreferencePickerRow(
                flag = flag,
                isActive = configState.isActive(flag),
                preference = preferences.preference(forFlag = flag),
                onPreferenceChange = {
                    onPreferenceChange(flag, it)
                }
            )
        }
    }
}

@Composable
private fun ConfigAllowSection(
    configState: ConfigObservable.State,
    preferences: ExperimentalPreferences,
    onAllowedChange: suspend (ConfigFlag, Boolean) -> Unit
) {
    ThemeListSection(
        header = "Allow",
        footer = "Disable a feature to opt this device out when it is enabled remotely."
    ) {
        AdvancedFlags.forEach { flag ->
            ConfigFlagAllowedRow(
                flag = flag,
                isActive = configState.isActive(flag),
                isAllowed = preferences.isAllowed(flag),
                onAllowedChange = {
                    onAllowedChange(flag, it)
                }
            )
        }
    }
}

@Composable
private fun ConfigFlagAllowedRow(
    flag: ConfigFlag,
    isActive: Boolean,
    isAllowed: Boolean,
    onAllowedChange: suspend (Boolean) -> Unit
) {
    ThemeSwitchRow(
        title = flag.localizedDescription,
        supportingText = flag.activeDescription(isActive),
        checked = isAllowed,
        onCheckedChange = {
            onAllowedChange(it)
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

private fun UserPreferencesObservable.updateExperimentalPreferencesSafely(
    coroutineScope: CoroutineScope,
    errorHandler: ErrorHandler,
    transform: (ExperimentalPreferences) -> ExperimentalPreferences
) {
    coroutineScope.launch {
        runCatchingNonFatal {
            updateExperimentalPreferences(transform)
        }.onFailure {
            errorHandler.report(it)
        }
    }
}
