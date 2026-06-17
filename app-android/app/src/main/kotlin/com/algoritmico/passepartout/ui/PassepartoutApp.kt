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
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.algoritmico.passepartout.observables.AppError
import com.algoritmico.passepartout.models.AppConfiguration
import com.algoritmico.passepartout.observables.ConfigObservable
import com.algoritmico.passepartout.observables.ErrorHandler
import com.algoritmico.passepartout.observables.LocalAppConfiguration
import com.algoritmico.passepartout.observables.LocalConfigObservable
import com.algoritmico.passepartout.observables.LocalErrorHandler
import com.algoritmico.passepartout.observables.LocalVersionObservable
import com.algoritmico.passepartout.observables.ProfileObservable
import com.algoritmico.passepartout.observables.TunnelObservable
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.observables.VersionObservable
import com.algoritmico.passepartout.ui.alerts.GenericErrorAlert
import com.algoritmico.passepartout.ui.app.AppCoordinator

@Composable
fun PassepartoutApp(
    logTag: String,
    profileObservable: ProfileObservable,
    tunnelObservable: TunnelObservable,
    userPreferencesObservable: UserPreferencesObservable,
    configObservable: ConfigObservable,
    versionObservable: VersionObservable,
    appConfiguration: AppConfiguration,
    errorHandler: ErrorHandler,
    onImportProfile: () -> Unit
) {
    val colorScheme = if (isSystemInDarkTheme()) {
        darkColorScheme(
            primary = Color(0xFFFFB878),
            onPrimary = Color(0xFF4A2600),
            primaryContainer = Color(0xFF6B3A0E),
            onPrimaryContainer = Color(0xFFFFDCC1),
            inversePrimary = Color(0xFF9A571B)
        )
    } else {
        lightColorScheme(
            primary = Color(0xFF9A571B),
            onPrimary = Color(0xFFFFFFFF),
            primaryContainer = Color(0xFFFFDCC1),
            onPrimaryContainer = Color(0xFF311300),
            inversePrimary = Color(0xFFFFB878)
        )
    }
    var lastError by remember {
        mutableStateOf<AppError?>(null)
    }
    CompositionLocalProvider(
        LocalAppConfiguration provides appConfiguration,
        LocalConfigObservable provides configObservable,
        LocalVersionObservable provides versionObservable,
        LocalErrorHandler provides errorHandler
    ) {
        MaterialTheme(colorScheme = colorScheme) {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background
            ) {
                AppCoordinator(
                    logTag,
                    title = "Passepartout",
                    profileObservable = profileObservable,
                    tunnelObservable = tunnelObservable,
                    userPreferencesObservable = userPreferencesObservable,
                    onImportProfile = onImportProfile
                )
            }
            LaunchedEffect(errorHandler) {
                errorHandler.errors.collect { error ->
                    lastError = error
                }
            }
            lastError?.let { error ->
                GenericErrorAlert(
                    error = error,
                    onDismiss = {
                        lastError = null
                    }
                )
            }
        }
    }
}
