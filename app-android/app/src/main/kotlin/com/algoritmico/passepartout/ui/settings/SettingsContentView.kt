// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.core.tween
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
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
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.ThemeImage
import com.algoritmico.passepartout.ui.theme.ThemeImageName
import com.algoritmico.passepartout.ui.theme.ThemeListSection
import com.algoritmico.passepartout.ui.theme.ThemeNavigatingButton

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
    val theme = LocalTheme.current
    val appConfiguration = LocalAppConfiguration.current
    val uriHandler = LocalUriHandler.current
    val errorHandler = LocalErrorHandler.current
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = theme.spacing.small)
    ) {
        item {
            ThemeListSection {
                linkContent(SettingsCoordinatorRoute.Preferences)
                linkContent(SettingsCoordinatorRoute.Version)
                versionUpdateContent()
            }
        }
        item {
            ThemeListSection(header = "About") {
                linkContent(SettingsCoordinatorRoute.Links)
                linkContent(SettingsCoordinatorRoute.Credits)
            }
        }
        item {
            ThemeListSection(header = "Troubleshooting") {
                ThemeNavigatingButton(
                    title = "FAQ",
                    onClick = {
                        uriHandler.safeOpenUri(appConfiguration.constants.websites.faqURL, errorHandler)
                    }
                )
                linkContent(SettingsCoordinatorRoute.Diagnostics)
            }
        }
    }
}

private val SettingsCoordinatorRoute?.routeIndex: Int
    get() = this?.index ?: -1
