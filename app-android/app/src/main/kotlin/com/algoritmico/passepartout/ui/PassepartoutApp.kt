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

@Composable
fun PassepartoutApp(
    profileObservable: ProfileObservable,
    tunnelObservable: TunnelObservable,
    onImportProfile: () -> Unit,
    onProfilesDelete: (Array<String>) -> Unit
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
                onProfilesDelete = onProfilesDelete,
                onImportProfile = onImportProfile
            )
        }
    }
}
