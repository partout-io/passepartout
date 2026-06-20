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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.business.extensions.versionString
import com.algoritmico.passepartout.ui.LocalAndroidConstants
import com.algoritmico.passepartout.ui.LocalAppConfiguration
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.ThemeNavigatingButton

@Composable
fun SettingsCoordinator(
    onDismissRequest: () -> Unit
) {
    var navigationRoute by rememberSaveable {
        mutableStateOf<SettingsCoordinatorRoute?>(null)
    }

    fun navigateBack() {
        navigationRoute = when (navigationRoute) {
            SettingsCoordinatorRoute.AppLog -> SettingsCoordinatorRoute.Diagnostics
            SettingsCoordinatorRoute.PreferencesAdvanced -> SettingsCoordinatorRoute.Preferences
            SettingsCoordinatorRoute.TunnelLog -> SettingsCoordinatorRoute.Diagnostics
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
            title = { route -> title(route) },
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
                    onRoute = {
                        navigationRoute = it
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
    ThemeNavigatingButton(
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
    onRoute: (SettingsCoordinatorRoute) -> Unit
) {
    val androidConstants = LocalAndroidConstants.current
    when (route) {
        SettingsCoordinatorRoute.AppLog -> {
            LogcatView(tags = androidConstants.logTags.appTags)
        }
        SettingsCoordinatorRoute.Credits -> CreditsView()
        SettingsCoordinatorRoute.Diagnostics -> {
            DiagnosticsView(
                onLiveLog = onRoute
            )
        }
        SettingsCoordinatorRoute.Links -> LinksView()
        SettingsCoordinatorRoute.Preferences -> {
            PreferencesView(
                onAdvanced = {
                    onRoute(SettingsCoordinatorRoute.PreferencesAdvanced)
                }
            )
        }
        SettingsCoordinatorRoute.PreferencesAdvanced -> PreferencesAdvancedView()
        SettingsCoordinatorRoute.TunnelLog -> {
            LogcatView(tags = androidConstants.logTags.serviceTags)
        }
        SettingsCoordinatorRoute.Version -> VersionView()
        null -> PlaceholderDestination(stringResource(R.string.global_nouns_no_selection))
    }
}

@Composable
private fun PlaceholderDestination(
    title: String
) {
    val theme = LocalTheme.current

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(theme.spacing.xxLarge),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.headlineSmall
        )
    }
}

@Composable
private fun title(route: SettingsCoordinatorRoute?): String {
    return when (route) {
        SettingsCoordinatorRoute.AppLog -> stringResource(R.string.views_diagnostics_rows_app)
        SettingsCoordinatorRoute.Credits -> stringResource(R.string.views_settings_credits_title)
        SettingsCoordinatorRoute.Diagnostics -> stringResource(R.string.views_diagnostics_title)
        SettingsCoordinatorRoute.Links -> stringResource(R.string.views_settings_links_title)
        SettingsCoordinatorRoute.Preferences -> stringResource(R.string.global_nouns_preferences)
        SettingsCoordinatorRoute.PreferencesAdvanced -> stringResource(R.string.global_nouns_advanced)
        SettingsCoordinatorRoute.TunnelLog -> stringResource(R.string.views_diagnostics_rows_tunnel)
        SettingsCoordinatorRoute.Version -> stringResource(R.string.app_name)
        null -> stringResource(R.string.views_settings_title)
    }
}

@Composable
private fun linkTitle(route: SettingsCoordinatorRoute): String {
    return when (route) {
        SettingsCoordinatorRoute.Version -> stringResource(R.string.global_nouns_version)
        else -> title(route)
    }
}

enum class SettingsCoordinatorRoute(
    val index: Int
) {
    Credits(0),
    Diagnostics(1),
    AppLog(2),
    TunnelLog(3),
    Links(4),
    Preferences(5),
    PreferencesAdvanced(6),
    Version(7)
}
