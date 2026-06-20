// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.core.tween
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import com.algoritmico.passepartout.business.extensions.faqURL
import com.algoritmico.passepartout.ui.LocalAppConfiguration
import com.algoritmico.passepartout.ui.LocalErrorHandler
import com.algoritmico.passepartout.observables.safeOpenUri
import com.algoritmico.passepartout.ui.theme.ThemeImage
import com.algoritmico.passepartout.ui.theme.ThemeImageName
import com.algoritmico.passepartout.ui.theme.ThemeList
import com.algoritmico.passepartout.ui.theme.ThemeNavigatingButton
import com.algoritmico.passepartout.ui.theme.themeListSection

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsContentView(
    navigationRoute: SettingsCoordinatorRoute?,
    title: (SettingsCoordinatorRoute?) -> String,
    linkContent: @Composable (SettingsCoordinatorRoute) -> Unit,
    versionUpdateContent: @Composable () -> Unit,
    settingsDestination: @Composable (SettingsCoordinatorRoute?) -> Unit,
    onBack: () -> Unit,
    onDismissRequest: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Scaffold(
            modifier = Modifier.fillMaxSize(),
            topBar = {
                TopAppBar(
                    title = {
                        Text(title(navigationRoute))
                    },
                    navigationIcon = {
                        if (navigationRoute != null) {
                            IconButton(
                                onClick = onBack
                            ) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                    contentDescription = "Back"
                                )
                            }
                        }
                    },
                    actions = {
                        if (navigationRoute == null) {
                            IconButton(
                                onClick = onDismissRequest
                            ) {
                                ThemeImage(
                                    name = ThemeImageName.close,
                                    contentDescription = "Close"
                                )
                            }
                        }
                    }
                )
            }
        ) { innerPadding ->
            AnimatedContent(
                modifier = Modifier.padding(innerPadding),
                targetState = navigationRoute,
                transitionSpec = {
                    val direction = if (targetState.routeIndex > initialState.routeIndex) {
                        AnimatedContentTransitionScope.SlideDirection.Left
                    } else {
                        AnimatedContentTransitionScope.SlideDirection.Right
                    }
                    slideIntoContainer(
                        towards = direction,
                        animationSpec = tween()
                    ) togetherWith slideOutOfContainer(
                        towards = direction,
                        animationSpec = tween()
                    ) using SizeTransform(clip = false)
                },
                label = "Settings navigation"
            ) { route ->
                if (route == null) {
                    SettingsListView(
                        linkContent = linkContent,
                        versionUpdateContent = versionUpdateContent
                    )
                } else {
                    settingsDestination(route)
                }
            }
        }
    }
}

@Composable
private fun SettingsListView(
    linkContent: @Composable (SettingsCoordinatorRoute) -> Unit,
    versionUpdateContent: @Composable () -> Unit
) {
    val appConfiguration = LocalAppConfiguration.current
    val uriHandler = LocalUriHandler.current
    val errorHandler = LocalErrorHandler.current
    ThemeList {
        themeListSection {
            item {
                linkContent(SettingsCoordinatorRoute.Preferences)
            }
            item {
                linkContent(SettingsCoordinatorRoute.Version)
            }
            item {
                versionUpdateContent()
            }
        }
        themeListSection(header = "About") {
            item {
                linkContent(SettingsCoordinatorRoute.Links)
            }
            item {
                linkContent(SettingsCoordinatorRoute.Credits)
            }
        }
        themeListSection(header = "Troubleshooting") {
            item {
                ThemeNavigatingButton(
                    title = "FAQ",
                    onClick = {
                        uriHandler.safeOpenUri(appConfiguration.constants.websites.faqURL, errorHandler)
                    }
                )
            }
            item {
                linkContent(SettingsCoordinatorRoute.Diagnostics)
            }
        }
    }
}

private val SettingsCoordinatorRoute?.routeIndex: Int
    get() = this?.index ?: -1
