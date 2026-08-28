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
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
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
    ThemeList(modifier = modifier) {
        themeListSection {
            item {
                PreferenceSwitchRow(
                    title = stringResource(R.string.views_preferences_dns_falls_back),
                    supportingText = stringResource(R.string.views_preferences_dns_falls_back_footer),
                    checked = AppPreferences::dnsFallsBack,
                    onCheckedChange = UserPreferencesObservable::updateDnsFallback
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
        themeListSection {
            item {
                CryptoBackendPickerRow()
            }
        }
    }
}

@Composable
private fun CryptoBackendPickerRow() {
    val userPreferencesObservable = LocalUserPreferencesObservable.current
    val initialPreferences = remember(userPreferencesObservable) {
        userPreferencesObservable.currentPreferences
    }
    val preferences by userPreferencesObservable.preferences.collectAsStateWithLifecycle(
        initialValue = initialPreferences
    )
    val coroutineScope = rememberCoroutineScope()
    val errorHandler = LocalErrorHandler.current
    var isMenuExpanded by rememberSaveable {
        mutableStateOf(false)
    }
    val selectedBackend = cryptoBackends.firstOrNull {
        (it?.value ?: 0) == preferences.cryptoBackend
    }

    fun update(backend: CryptoBackend?) {
        isMenuExpanded = false
        coroutineScope.launch {
            runCatchingNonFatal {
                userPreferencesObservable.updateCryptoBackend(backend?.value ?: 0)
            }.onFailure {
                errorHandler.report(it)
            }
        }
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
                                update(backend)
                            }
                        )
                    }
                }
            }
        },
        modifier = Modifier.fillMaxWidth()
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
