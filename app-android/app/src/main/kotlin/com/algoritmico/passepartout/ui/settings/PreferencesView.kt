// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.models.AppPreferenceKey
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
    val userPreferencesObservable = LocalUserPreferencesObservable.current
    val preferences by userPreferencesObservable.preferences.collectAsStateWithLifecycle(
        initialValue = userPreferencesObservable.currentPreferences
    )
    var dnsFallback by rememberSaveable(userPreferencesObservable) {
        mutableStateOf(userPreferencesObservable.currentPreferences.dnsFallsBack)
    }

    LaunchedEffect(preferences.dnsFallsBack) {
        dnsFallback = preferences.dnsFallsBack
    }

    ThemeList(modifier = modifier) {
        themeListSection {
            item {
                ThemeSwitchRow(
                    title = stringResource(R.string.views_preferences_dns_falls_back),
                    supportingText = stringResource(R.string.views_preferences_dns_falls_back_footer),
                    checked = dnsFallback,
                    onCheckedChange = { isChecked ->
                        val previousValue = dnsFallback
                        dnsFallback = isChecked
                        try {
                            userPreferencesObservable.updateDnsFallback(isChecked)
                        } catch (error: Exception) {
                            dnsFallback = previousValue
                            throw error
                        }
                    }
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

private suspend fun UserPreferencesObservable.updateDnsFallback(
    isEnabled: Boolean
) {
    updatePreferences(
        fields = listOf(AppPreferenceKey.dnsFallsBack)
    ) {
        it.copy(dnsFallsBack = isEnabled)
    }
}
