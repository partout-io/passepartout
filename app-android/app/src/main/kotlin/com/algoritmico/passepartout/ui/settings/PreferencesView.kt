// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.isDebuggable
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.ui.LocalErrorHandler
import com.algoritmico.passepartout.ui.LocalUserPreferencesObservable
import com.algoritmico.passepartout.ui.Strings
import com.algoritmico.passepartout.ui.theme.ThemeList
import com.algoritmico.passepartout.ui.theme.ThemeSwitchRow
import com.algoritmico.passepartout.ui.theme.themeListSection
import io.partout.models.CryptoBackend
import kotlinx.coroutines.launch

@Composable
fun PreferencesView(
    modifier: Modifier = Modifier,
    onAdvanced: () -> Unit
) {
    val isDebuggable = LocalContext.current.isDebuggable
    ThemeList(modifier = modifier) {
        themeListSection {
            item {
                PreferenceSwitchRow(
                    title = stringResource(R.string.views_preferences_dns_falls_back),
                    supportingText = stringResource(R.string.views_preferences_dns_falls_back_footer),
                    checked = AppPreferences::dnsFallsBack,
                    onCheckedChange = UserPreferencesObservable::updateDnsFallback
                )
                PreferenceDropdownRow(
                    title = stringResource(R.string.views_preferences_crypto_backend),
                    values = cryptoBackends,
                    selectedValue = { preferences ->
                        cryptoBackends.firstOrNull {
                            (it?.value ?: 0) == preferences.cryptoBackend
                        }
                    },
                    valueDescription = {
                        it.localizedDescription()
                    },
                    onValueChange = {
                        updateCryptoBackend(it?.value ?: 0)
                    }
                )
            }
            // Hide "Advanced" because there are no actionable config flags
//            item {
//                ThemeNavigatingButton(
//                    title = stringResource(R.string.global_nouns_advanced),
//                    onClick = onAdvanced
//                )
//            }
        }
    }
}

@Composable
private fun <Value> PreferenceDropdownRow(
    title: String,
    values: List<Value>,
    selectedValue: (AppPreferences) -> Value,
    valueDescription: @Composable (Value) -> String,
    onValueChange: suspend UserPreferencesObservable.(Value) -> Unit,
    modifier: Modifier = Modifier,
    supportingText: String? = null,
    enabled: Boolean = true
) {
    val userPreferencesObservable = LocalUserPreferencesObservable.current
    val initialPreferences = remember(userPreferencesObservable) {
        userPreferencesObservable.currentPreferences
    }
    val preferences by userPreferencesObservable.preferences.collectAsStateWithLifecycle(
        initialValue = initialPreferences
    )
    val coroutineScope = rememberCoroutineScope()
    val errorHandler = LocalErrorHandler.current
    var isMenuExpanded by rememberSaveable(title) {
        mutableStateOf(false)
    }
    val selected = selectedValue(preferences)

    fun update(value: Value) {
        isMenuExpanded = false
        coroutineScope.launch {
            runCatchingNonFatal {
                userPreferencesObservable.onValueChange(value)
            }.onFailure {
                errorHandler.report(it)
            }
        }
    }

    ListItem(
        headlineContent = {
            Text(title)
        },
        supportingContent = supportingText?.let { text ->
            {
                Text(text)
            }
        },
        trailingContent = {
            Box {
                TextButton(
                    enabled = enabled,
                    onClick = {
                        isMenuExpanded = true
                    }
                ) {
                    Text(valueDescription(selected))
                }
                DropdownMenu(
                    expanded = isMenuExpanded,
                    onDismissRequest = {
                        isMenuExpanded = false
                    }
                ) {
                    values.forEach { value ->
                        DropdownMenuItem(
                            text = {
                                Text(valueDescription(value))
                            },
                            onClick = {
                                update(value)
                            }
                        )
                    }
                }
            }
        },
        modifier = modifier.fillMaxWidth()
    )
}

private val cryptoBackends: List<CryptoBackend?> = listOf(
    null,
    CryptoBackend.openssl,
    CryptoBackend.mbedtls
)

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

@Composable
private fun PreferenceSwitchRow(
    title: String,
    checked: (AppPreferences) -> Boolean,
    modifier: Modifier = Modifier,
    supportingText: String? = null,
    enabled: Boolean = true,
    onCheckedChange: suspend UserPreferencesObservable.(Boolean) -> Unit
) {
    val userPreferencesObservable = LocalUserPreferencesObservable.current
    val initialPreferences = remember(userPreferencesObservable) {
        userPreferencesObservable.currentPreferences
    }
    val preferences by userPreferencesObservable.preferences.collectAsStateWithLifecycle(
        initialValue = initialPreferences
    )
    val upstreamChecked = checked(preferences)
    var localChecked by rememberSaveable(title) {
        mutableStateOf(checked(initialPreferences))
    }

    LaunchedEffect(upstreamChecked) {
        localChecked = upstreamChecked
    }

    ThemeSwitchRow(
        title = title,
        checked = localChecked,
        modifier = modifier,
        supportingText = supportingText,
        enabled = enabled,
        onCheckedChange = { isChecked ->
            val previousValue = localChecked
            localChecked = isChecked
            try {
                userPreferencesObservable.onCheckedChange(isChecked)
            } catch (error: Exception) {
                localChecked = previousValue
                throw error
            }
        }
    )
}
