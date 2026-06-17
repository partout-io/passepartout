// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.algoritmico.passepartout.extensions.versionString
import com.algoritmico.passepartout.observables.LocalAppConfiguration
import com.algoritmico.passepartout.observables.UserPreferencesObservable

@Composable
fun SettingsCoordinator(
    userPreferencesObservable: UserPreferencesObservable,
    onDismissRequest: () -> Unit
) {
    var navigationRoute by rememberSaveable {
        mutableStateOf<SettingsCoordinatorRoute?>(null)
    }

    fun navigateBack() {
        navigationRoute = when (navigationRoute) {
            SettingsCoordinatorRoute.PreferencesAdvanced -> SettingsCoordinatorRoute.Preferences
            else -> null
        }
    }

    BackHandler(enabled = navigationRoute != null) {
        navigateBack()
    }

    Dialog(
        onDismissRequest = onDismissRequest,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        SettingsContentView(
            navigationRoute = navigationRoute,
            title = ::title,
            linkContent = { route ->
                LinkView(
                    route = route,
                    onRoute = {
                        navigationRoute = it
                    }
                )
            },
            versionUpdateContent = {
                VersionUpdateLink()
            },
            settingsDestination = { route ->
                PushDestination(
                    route = route,
                    userPreferencesObservable = userPreferencesObservable,
                    onAdvanced = {
                        navigationRoute = SettingsCoordinatorRoute.PreferencesAdvanced
                    }
                )
            },
            onBack = ::navigateBack,
            onDismissRequest = onDismissRequest
        )
    }
}

@Composable
private fun LinkView(
    route: SettingsCoordinatorRoute,
    onRoute: (SettingsCoordinatorRoute) -> Unit
) {
    val appConfiguration = LocalAppConfiguration.current
    SettingsLinkRow(
        title = linkTitle(route),
        trailingText = if (route == SettingsCoordinatorRoute.Version) {
            appConfiguration.bundle.versionString
        } else {
            null
        },
        onClick = {
            onRoute(route)
        }
    )
}

@Composable
private fun PushDestination(
    route: SettingsCoordinatorRoute?,
    userPreferencesObservable: UserPreferencesObservable,
    onAdvanced: () -> Unit
) {
    when (route) {
        SettingsCoordinatorRoute.Credits -> CreditsView()
        SettingsCoordinatorRoute.Diagnostics -> PlaceholderDestination("Diagnostics")
        SettingsCoordinatorRoute.Links -> LinksView()
        SettingsCoordinatorRoute.Preferences -> {
            PreferencesView(
                userPreferencesObservable = userPreferencesObservable,
                onAdvanced = onAdvanced
            )
        }
        SettingsCoordinatorRoute.PreferencesAdvanced -> {
            PreferencesAdvancedView(
                userPreferencesObservable = userPreferencesObservable
            )
        }
        SettingsCoordinatorRoute.Version -> VersionView()
        null -> PlaceholderDestination("No selection")
    }
}

@Composable
private fun PlaceholderDestination(
    title: String
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.headlineSmall
        )
    }
}

private fun title(route: SettingsCoordinatorRoute?): String {
    return when (route) {
        SettingsCoordinatorRoute.Credits -> "Credits"
        SettingsCoordinatorRoute.Diagnostics -> "Diagnostics"
        SettingsCoordinatorRoute.Links -> "Links"
        SettingsCoordinatorRoute.Preferences -> "Preferences"
        SettingsCoordinatorRoute.PreferencesAdvanced -> "Advanced"
        SettingsCoordinatorRoute.Version -> "Passepartout"
        null -> "Settings"
    }
}

private fun linkTitle(route: SettingsCoordinatorRoute): String {
    return when (route) {
        SettingsCoordinatorRoute.Version -> "Version"
        else -> title(route)
    }
}

enum class SettingsCoordinatorRoute(
    val index: Int
) {
    Credits(0),
    Diagnostics(1),
    Links(2),
    Preferences(3),
    PreferencesAdvanced(4),
    Version(5)
}
