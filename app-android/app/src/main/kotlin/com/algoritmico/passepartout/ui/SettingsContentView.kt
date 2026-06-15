// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.core.tween
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.algoritmico.passepartout.extensions.faqURL
import com.algoritmico.passepartout.observables.LocalAppConfiguration

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
                                    imageVector = BackIcon,
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
                                Icon(
                                    imageVector = CloseIcon,
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

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        item {
            SettingsSection {
                linkContent(SettingsCoordinatorRoute.Preferences)
                linkContent(SettingsCoordinatorRoute.Version)
                versionUpdateContent()
            }
        }
        item {
            SettingsSection(header = "About") {
                linkContent(SettingsCoordinatorRoute.Links)
                linkContent(SettingsCoordinatorRoute.Credits)
            }
        }
        item {
            SettingsSection(header = "Troubleshooting") {
                SettingsLinkRow(
                    title = "FAQ",
                    onClick = {
                        uriHandler.openUri(appConfiguration.constants.websites.faqURL)
                    }
                )
                linkContent(SettingsCoordinatorRoute.Diagnostics)
            }
        }
    }
}

@Composable
private fun SettingsSection(
    header: String? = null,
    content: @Composable () -> Unit
) {
    Column {
        if (header != null) {
            Text(
                text = header,
                modifier = Modifier.padding(
                    start = 16.dp,
                    top = 20.dp,
                    end = 16.dp,
                    bottom = 8.dp
                ),
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.SemiBold
            )
        }
        content()
        HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
    }
}

@Composable
fun SettingsLinkRow(
    title: String,
    trailingText: String? = null,
    onClick: () -> Unit
) {
    ListItem(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        headlineContent = {
            Text(title)
        },
        trailingContent = {
            if (trailingText != null) {
                ListItemTrailingText(trailingText)
            } else {
                Icon(
                    imageVector = ChevronRightIcon,
                    contentDescription = null
                )
            }
        }
    )
}

private val SettingsCoordinatorRoute?.routeIndex: Int
    get() = this?.index ?: -1

private val CloseIcon: ImageVector
    get() = ImageVector.Builder(
        name = "Close",
        defaultWidth = 24.dp,
        defaultHeight = 24.dp,
        viewportWidth = 24f,
        viewportHeight = 24f
    ).apply {
        path(
            fill = SolidColor(Color.Black),
            pathFillType = PathFillType.NonZero
        ) {
            moveTo(18.3f, 5.71f)
            lineTo(16.89f, 4.29f)
            lineTo(12f, 9.17f)
            lineTo(7.11f, 4.29f)
            lineTo(5.7f, 5.71f)
            lineTo(10.59f, 10.59f)
            lineTo(5.7f, 15.48f)
            lineTo(7.11f, 16.9f)
            lineTo(12f, 12f)
            lineTo(16.89f, 16.9f)
            lineTo(18.3f, 15.48f)
            lineTo(13.41f, 10.59f)
            close()
        }
    }.build()

private val BackIcon: ImageVector
    get() = ImageVector.Builder(
        name = "Back",
        defaultWidth = 24.dp,
        defaultHeight = 24.dp,
        viewportWidth = 24f,
        viewportHeight = 24f
    ).apply {
        path(
            fill = SolidColor(Color.Black),
            pathFillType = PathFillType.NonZero
        ) {
            moveTo(20f, 11f)
            horizontalLineTo(7.83f)
            lineTo(13.42f, 5.41f)
            lineTo(12f, 4f)
            lineTo(4f, 12f)
            lineTo(12f, 20f)
            lineTo(13.41f, 18.59f)
            lineTo(7.83f, 13f)
            horizontalLineTo(20f)
            close()
        }
    }.build()

private val ChevronRightIcon: ImageVector
    get() = ImageVector.Builder(
        name = "ChevronRight",
        defaultWidth = 24.dp,
        defaultHeight = 24.dp,
        viewportWidth = 24f,
        viewportHeight = 24f
    ).apply {
        path(
            fill = SolidColor(Color.Black),
            pathFillType = PathFillType.NonZero
        ) {
            moveTo(10f, 6f)
            lineTo(8.59f, 7.41f)
            lineTo(13.17f, 12f)
            lineTo(8.59f, 16.59f)
            lineTo(10f, 18f)
            lineTo(16f, 12f)
            close()
        }
    }.build()
