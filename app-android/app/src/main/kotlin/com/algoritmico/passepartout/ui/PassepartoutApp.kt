// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.algoritmico.passepartout.observables.ProfileObservable
import com.algoritmico.passepartout.observables.TunnelObservable
import com.algoritmico.passepartout.observables.UserPreferencesObservable

@Composable
fun PassepartoutApp(
    profileObservable: ProfileObservable,
    tunnelObservable: TunnelObservable,
    userPreferencesObservable: UserPreferencesObservable,
    onImportProfile: () -> Unit
) {
    val colorScheme = if (isSystemInDarkTheme()) {
        darkColorScheme()
    } else {
        lightColorScheme()
    }

    MaterialTheme(colorScheme = colorScheme) {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            AppCoordinator(
                title = "Passepartout",
                profileObservable = profileObservable,
                tunnelObservable = tunnelObservable,
                userPreferencesObservable = userPreferencesObservable,
                onImportProfile = onImportProfile
            )
        }
    }
}
