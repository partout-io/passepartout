// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.algoritmico.passepartout.abi.models.AppConfiguration
import com.algoritmico.passepartout.observables.ConfigObservable
import com.algoritmico.passepartout.observables.IAPObservable
import com.algoritmico.passepartout.observables.LocalAppConfiguration
import com.algoritmico.passepartout.observables.LocalConfigObservable
import com.algoritmico.passepartout.observables.LocalIAPObservable
import com.algoritmico.passepartout.observables.LocalVersionObservable
import com.algoritmico.passepartout.observables.ProfileObservable
import com.algoritmico.passepartout.observables.TunnelObservable
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.observables.VersionObservable

@Composable
fun PassepartoutApp(
    profileObservable: ProfileObservable,
    tunnelObservable: TunnelObservable,
    userPreferencesObservable: UserPreferencesObservable,
    configObservable: ConfigObservable,
    iapObservable: IAPObservable,
    versionObservable: VersionObservable,
    appConfiguration: AppConfiguration,
    importFailureMessage: String?,
    onDismissImportFailure: () -> Unit,
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

    CompositionLocalProvider(
        LocalAppConfiguration provides appConfiguration,
        LocalConfigObservable provides configObservable,
        LocalIAPObservable provides iapObservable,
        LocalVersionObservable provides versionObservable
    ) {
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
            importFailureMessage?.let { message ->
                ImportFailureAlert(
                    message = message,
                    onDismiss = onDismissImportFailure
                )
            }
        }
    }
}

@Composable
private fun ImportFailureAlert(
    message: String,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text("Import failed")
        },
        text = {
            Text(message)
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("OK")
            }
        }
    )
}
