// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.business.extensions.disable
import com.algoritmico.passepartout.business.extensions.enable
import com.algoritmico.passepartout.business.extensions.isAllowed
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.extensions.setAllowed
import com.algoritmico.passepartout.business.extensions.unignore
import com.algoritmico.passepartout.context.isBetaSuggestedByAndroidAPI
import com.algoritmico.passepartout.models.ConfigFlag
import com.algoritmico.passepartout.models.DistributionTarget
import com.algoritmico.passepartout.models.ExperimentalPreferences
import com.algoritmico.passepartout.observables.ConfigObservable
import com.algoritmico.passepartout.ui.LocalAppConfiguration
import com.algoritmico.passepartout.ui.LocalConfigObservable
import com.algoritmico.passepartout.ui.LocalErrorHandler
import com.algoritmico.passepartout.ui.LocalUserPreferencesObservable
import com.algoritmico.passepartout.ui.Strings
import com.algoritmico.passepartout.ui.theme.ThemeList
import com.algoritmico.passepartout.ui.theme.ThemeSwitchRow
import com.algoritmico.passepartout.ui.theme.themeListSection
import io.partout.models.CryptoBackend
import kotlinx.coroutines.launch

@Composable
fun PreferencesAdvancedView(
    modifier: Modifier = Modifier
) {
    val appConfiguration = LocalAppConfiguration.current
    val isBeta = LocalContext.current.isBetaSuggestedByAndroidAPI
    val configState by LocalConfigObservable.current.state.collectAsStateWithLifecycle()
    val userPreferencesObservable = LocalUserPreferencesObservable.current
    val initialPreferences = remember(userPreferencesObservable) {
        userPreferencesObservable.currentPreferences
    }
    val preferences by userPreferencesObservable.preferences.collectAsStateWithLifecycle(
        initialValue = initialPreferences
    )
    val coroutineScope = rememberCoroutineScope()
    val canOverride = isBeta || appConfiguration.bundle.distributionTarget == DistributionTarget.developerID
    val errorHandler = LocalErrorHandler.current

    fun updateSafely(block: suspend () -> Unit) {
        coroutineScope.launch {
            runCatchingNonFatal {
                block()
            }.onFailure {
                errorHandler.report(it)
            }
        }
    }

    AdvancedPreferencesContent(
        modifier = modifier,
        canOverride = canOverride,
        configState = configState,
        preferences = preferences.experimental,
        cryptoBackend = preferences.cryptoBackend,
        onPreferenceChange = { flag, preference ->
            updateSafely {
                userPreferencesObservable.updateExperimentalPreferences {
                    it.setPreference(preference, forFlag = flag)
                }
            }
        },
        onAllowedChange = { flag, isAllowed ->
            userPreferencesObservable.updateExperimentalPreferences {
                it.setAllowed(flag, isAllowed)
            }
        },
        onCryptoBackendChange = {
            updateSafely {
                userPreferencesObservable.updateCryptoBackend(it)
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
    cryptoBackend: Int,
    onPreferenceChange: (ConfigFlag, ConfigFlagPreference) -> Unit,
    onAllowedChange: suspend (ConfigFlag, Boolean) -> Unit,
    onCryptoBackendChange: (Int) -> Unit
) {
    val allowHeader = stringResource(R.string.global_actions_allow)
    val overrideFooter = stringResource(R.string.views_preferences_advanced_override_footer)
    val remoteFooter = stringResource(R.string.views_preferences_advanced_remote_footer)

    ThemeList(modifier = modifier) {
        // Hide as long as config flags are empty.
//        if (canOverride) {
//            themeListSection(
//                footer = overrideFooter
//            ) {
//                items(advancedFlags) { flag ->
//                    ConfigPreferencePickerRow(
//                        flag = flag,
//                        isActive = configState.isActive(flag),
//                        preference = preferences.preference(forFlag = flag),
//                        onPreferenceChange = {
//                            onPreferenceChange(flag, it)
//                        }
//                    )
//                }
//            }
//        } else {
//            themeListSection(
//                header = allowHeader,
//                footer = remoteFooter
//            ) {
//                items(advancedFlags) { flag ->
//                    ConfigFlagAllowedRow(
//                        flag = flag,
//                        isActive = configState.isActive(flag),
//                        isAllowed = preferences.isAllowed(flag),
//                        onAllowedChange = {
//                            onAllowedChange(flag, it)
//                        }
//                    )
//                }
//            }
//        }
        themeListSection {
            item {
                CryptoBackendPickerRow(
                    cryptoBackend = cryptoBackend,
                    onCryptoBackendChange = onCryptoBackendChange
                )
            }
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
                    Text(preference.localizedDescription())
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
                                Text(item.localizedDescription())
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

@Composable
private fun CryptoBackendPickerRow(
    cryptoBackend: Int,
    onCryptoBackendChange: (Int) -> Unit
) {
    var isMenuExpanded by rememberSaveable {
        mutableStateOf(false)
    }
    val selectedBackend = cryptoBackends.firstOrNull {
        (it?.value ?: 0) == cryptoBackend
    }

    ListItem(
        headlineContent = {
            Text(stringResource(R.string.views_preferences_crypto_backend))
        },
        trailingContent = {
            Box {
                TextButton(
                    onClick = {
                        isMenuExpanded = true
                    }
                ) {
                    Text(selectedBackend.localizedDescription())
                }
                DropdownMenu(
                    expanded = isMenuExpanded,
                    onDismissRequest = {
                        isMenuExpanded = false
                    }
                ) {
                    cryptoBackends.forEach { backend ->
                        DropdownMenuItem(
                            text = {
                                Text(backend.localizedDescription())
                            },
                            onClick = {
                                isMenuExpanded = false
                                onCryptoBackendChange(backend?.value ?: 0)
                            }
                        )
                    }
                }
            }
        },
        modifier = Modifier.fillMaxWidth()
    )
}

private val advancedFlags = listOf(
    ConfigFlag.zigRuntime,
    ConfigFlag.zigOpenVPN,
    ConfigFlag.zigWireGuard
)

private val cryptoBackends: List<CryptoBackend?> = listOf(
    null,
    CryptoBackend.openssl,
    CryptoBackend.mbedtls
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

@Composable
private fun ConfigFlag.activeDescription(
    isActive: Boolean
): String {
    return if (isActive) {
        stringResource(R.string.global_nouns_enabled)
    } else {
        stringResource(R.string.global_nouns_disabled)
    }
}

@Composable
private fun ConfigFlagPreference.localizedDescription(): String {
    return when (this) {
        ConfigFlagPreference.Remote -> stringResource(R.string.views_preferences_advanced_override_picker_remote)
        ConfigFlagPreference.Enable -> stringResource(R.string.global_actions_enable)
        ConfigFlagPreference.Disable -> stringResource(R.string.global_actions_disable)
    }
}

@Composable
private fun CryptoBackend?.localizedDescription(): String {
    return when (this) {
        null -> stringResource(R.string.global_nouns_default)
        CryptoBackend.openssl -> Strings.Unlocalized.Crypto.openSSL
        CryptoBackend.mbedtls -> Strings.Unlocalized.Crypto.mbedTLS
        CryptoBackend.native -> error("Unsupported crypto backend: $this")
        CryptoBackend.mock -> Strings.Unlocalized.Crypto.mock
    }
}
