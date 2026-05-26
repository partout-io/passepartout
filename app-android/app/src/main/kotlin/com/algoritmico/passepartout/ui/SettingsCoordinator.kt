// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.core.tween
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsCoordinator(
    userPreferencesObservable: UserPreferencesObservable,
    onDismissRequest: () -> Unit
) {
    var route by rememberSaveable {
        mutableStateOf(SettingsRoute.Settings)
    }

    BackHandler(enabled = route != SettingsRoute.Settings) {
        route = SettingsRoute.Settings
    }

    Dialog(
        onDismissRequest = onDismissRequest,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        SettingsCoordinatorContent(
            route = route,
            userPreferencesObservable,
            onRoute = {
                route = it
            },
            onDismissRequest = onDismissRequest
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SettingsCoordinatorContent(
    route: SettingsRoute,
    userPreferencesObservable: UserPreferencesObservable,
    onRoute: (SettingsRoute) -> Unit,
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
                        Text(route.title)
                    },
                    navigationIcon = {
                        IconButton(
                            onClick = {
                                if (route == SettingsRoute.Settings) {
                                    onDismissRequest()
                                } else {
                                    onRoute(SettingsRoute.Settings)
                                }
                            }
                        ) {
                            Icon(
                                imageVector = if (route == SettingsRoute.Settings) {
                                    CloseIcon
                                } else {
                                    BackIcon
                                },
                                contentDescription = if (route == SettingsRoute.Settings) {
                                    "Close"
                                } else {
                                    "Back"
                                }
                            )
                        }
                    }
                )
            }
        ) { innerPadding ->
            AnimatedContent(
                targetState = route,
                transitionSpec = {
                    val direction = if (targetState.index > initialState.index) {
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
            ) { currentRoute ->
                when (currentRoute) {
                    SettingsRoute.Settings -> {
                        SettingsRootView(
                            modifier = Modifier.padding(innerPadding),
                            onPreferences = {
                                onRoute(SettingsRoute.Preferences)
                            }
                        )
                    }
                    SettingsRoute.Preferences -> {
                        PreferencesView(
                            modifier = Modifier.padding(innerPadding),
                            userPreferencesObservable
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun SettingsRootView(
    modifier: Modifier = Modifier,
    onPreferences: () -> Unit
) {
    ListItem(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onPreferences),
        headlineContent = {
            Text("Preferences")
        },
        trailingContent = {
            Icon(
                imageVector = ChevronRightIcon,
                contentDescription = null
            )
        }
    )
    HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
}

private enum class SettingsRoute(
    val title: String,
    val index: Int
) {
    Settings("Settings", 0),
    Preferences("Preferences", 1)
}

//@Preview(showBackground = true, widthDp = 393, heightDp = 852)
//@Composable
//private fun SettingsCoordinatorPreview() {
//    MaterialTheme {
//        SettingsCoordinatorContent(
//            route = SettingsRoute.Settings,
//            onRoute = {},
//            onDismissRequest = {}
//        )
//    }
//}
//
//@Preview(showBackground = true, widthDp = 393, heightDp = 852)
//@Composable
//private fun SettingsCoordinatorPreferencesPreview() {
//    MaterialTheme {
//        SettingsCoordinatorContent(
//            route = SettingsRoute.Preferences,
//            onRoute = {},
//            onDismissRequest = {}
//        )
//    }
//}

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
