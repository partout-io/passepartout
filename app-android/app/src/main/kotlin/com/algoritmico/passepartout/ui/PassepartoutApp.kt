// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.algoritmico.passepartout.observables.AppError
import com.algoritmico.passepartout.models.AppConfiguration
import com.algoritmico.passepartout.observables.ConfigObservable
import com.algoritmico.passepartout.observables.DiagnosticsObservable
import com.algoritmico.passepartout.observables.ErrorHandler
import com.algoritmico.passepartout.observables.ProfileObservable
import com.algoritmico.passepartout.observables.TunnelObservable
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.observables.VersionObservable
import com.algoritmico.passepartout.ui.alerts.GenericErrorAlert
import com.algoritmico.passepartout.ui.app.AppCoordinator
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.Theme

@Composable
fun PassepartoutApp(
    logTag: String,
    profileObservable: ProfileObservable,
    tunnelObservable: TunnelObservable,
    userPreferencesObservable: UserPreferencesObservable,
    configObservable: ConfigObservable,
    diagnosticsObservable: DiagnosticsObservable,
    versionObservable: VersionObservable,
    appConfiguration: AppConfiguration,
    errorHandler: ErrorHandler,
    theme: Theme = Theme(),
    onImportProfile: () -> Unit
) {
    val colorScheme = theme.colorScheme(isDark = isSystemInDarkTheme())
    var lastError by remember {
        mutableStateOf<AppError?>(null)
    }
    CompositionLocalProvider(
        LocalTheme provides theme,
        LocalAppConfiguration provides appConfiguration,
        LocalConfigObservable provides configObservable,
        LocalDiagnosticsObservable provides diagnosticsObservable,
        LocalProfileObservable provides profileObservable,
        LocalTunnelObservable provides tunnelObservable,
        LocalUserPreferencesObservable provides userPreferencesObservable,
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
