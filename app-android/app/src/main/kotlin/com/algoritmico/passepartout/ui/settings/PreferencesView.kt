// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.ui.LocalUserPreferencesObservable
import com.algoritmico.passepartout.ui.theme.ThemeList
import com.algoritmico.passepartout.ui.theme.ThemeSwitchRow
import com.algoritmico.passepartout.ui.theme.themeListSection

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
//                    title = "Advanced",
//                    onClick = onAdvanced
//                )
//            }
        }
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
