// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.app

import android.util.Log
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.observables.LocalErrorHandler
import com.algoritmico.passepartout.observables.ProfileObservable
import com.algoritmico.passepartout.observables.TunnelObservable
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.ui.settings.SettingsCoordinator
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppCoordinator(
    logTag: String,
    title: String,
    profileObservable: ProfileObservable,
    tunnelObservable: TunnelObservable,
    userPreferencesObservable: UserPreferencesObservable,
    onImportProfile: () -> Unit
) {
    var contextualProfileIds by rememberSaveable {
        mutableStateOf(emptyList<String>())
    }
    var isSettingsPresented by rememberSaveable {
        mutableStateOf(false)
    }
    val coroutineScope = rememberCoroutineScope()
    val isContextualMode = contextualProfileIds.isNotEmpty()
    val errorHandler = LocalErrorHandler.current

    fun clearContextualMode() {
        contextualProfileIds = emptyList()
    }

    fun toggleContextualProfile(profileId: String) {
        contextualProfileIds = if (profileId in contextualProfileIds) {
            contextualProfileIds - profileId
        } else {
            contextualProfileIds + profileId
        }
    }

    if (isContextualMode) {
        BackHandler {
            clearContextualMode()
        }
    }

    AppCoordinatorScaffold(
        title = title,
        contextualProfileCount = contextualProfileIds.size,
        onClearContextualMode = ::clearContextualMode,
        onDeleteProfiles = {
            val profileIds = contextualProfileIds
            clearContextualMode()
            coroutineScope.launch {
                runCatchingNonFatal {
                    profileObservable.remove(profileIds)
                }.onFailure {
                    Log.e(logTag, "Unable to delete profiles", it)
                    errorHandler.report(it)
                }
            }
        },
        onSettings = {
            isSettingsPresented = true
        },
        onImportProfile = onImportProfile
    ) { modifier ->
        ProfileContainerView(
            modifier = modifier,
            profileObservable = profileObservable,
            tunnelObservable = tunnelObservable,
            contextualProfileIds = contextualProfileIds,
            onContextualProfileSelected = ::toggleContextualProfile,
            onContextualProfileAction = { profileId ->
                contextualProfileIds = contextualProfileIds + profileId
            },
            onImportProfile = onImportProfile
        )
    }

    if (isSettingsPresented) {
        SettingsCoordinator(
            userPreferencesObservable,
            onDismissRequest = {
                isSettingsPresented = false
            }
        )
    }

}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AppCoordinatorScaffold(
    title: String,
    contextualProfileCount: Int,
    onClearContextualMode: () -> Unit,
    onDeleteProfiles: () -> Unit,
    onSettings: () -> Unit,
    onImportProfile: () -> Unit,
    content: @Composable (Modifier) -> Unit
) {
    var isAddSheetPresented by rememberSaveable {
        mutableStateOf(false)
    }
    val isContextualMode = contextualProfileCount > 0

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    if (isContextualMode) {
                        Text("$contextualProfileCount selected")
                    } else {
                        Text(title)
                    }
                },
                navigationIcon = {
                    if (isContextualMode) {
                        IconButton(
                            onClick = onClearContextualMode
                        ) {
                            Icon(
                                imageVector = CloseIcon,
                                contentDescription = "Cancel"
                            )
                        }
                    }
                },
                actions = {
                    if (isContextualMode) {
                        IconButton(
                            onClick = onDeleteProfiles
                        ) {
                            Icon(
                                imageVector = DeleteIcon,
                                contentDescription = "Delete profiles"
                            )
                        }
                    } else {
                        IconButton(
                            onClick = onSettings
                        ) {
                            Icon(
                                imageVector = SettingsIcon,
                                contentDescription = "Settings"
                            )
                        }
                    }
                }
            )
        },
        floatingActionButton = {
            if (!isContextualMode) {
                FloatingActionButton(
                    onClick = {
                        isAddSheetPresented = true
                    }
                ) {
                    Icon(
                        imageVector = AddIcon,
                        contentDescription = "Add profile"
                    )
                }
            }
        }
    ) { innerPadding ->
        content(
            Modifier
                .fillMaxSize()
                .padding(innerPadding)
        )
    }

    if (isAddSheetPresented) {
        ModalBottomSheet(
            onDismissRequest = {
                isAddSheetPresented = false
            }
        ) {
            ListItem(
                headlineContent = {
                    Text("Import file")
                },
                leadingContent = {
                    Icon(
                        imageVector = ImportFileIcon,
                        contentDescription = null
                    )
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable {
                        isAddSheetPresented = false
                        onImportProfile()
                    }
                    .padding(bottom = 24.dp)
            )
        }
    }
}

@Preview(showBackground = true, widthDp = 393, heightDp = 852)
@Composable
private fun AppCoordinatorPreview() {
    MaterialTheme {
        AppCoordinatorScaffold(
            title = "Passepartout",
            contextualProfileCount = 0,
            onClearContextualMode = {},
            onDeleteProfiles = {},
            onSettings = {},
            onImportProfile = {}
        ) { modifier ->
            Box(
                modifier = modifier,
                contentAlignment = Alignment.Center
            ) {
                Text("Profiles")
            }
        }
    }
}

@Preview(showBackground = true, widthDp = 393, heightDp = 852)
@Composable
private fun AppCoordinatorContextualPreview() {
    MaterialTheme {
        AppCoordinatorScaffold(
            title = "Passepartout",
            contextualProfileCount = 2,
            onClearContextualMode = {},
            onDeleteProfiles = {},
            onSettings = {},
            onImportProfile = {}
        ) { modifier ->
            Box(
                modifier = modifier,
                contentAlignment = Alignment.Center
            ) {
                Text("Profiles")
            }
        }
    }
}

private val AddIcon: ImageVector
    get() = ImageVector.Builder(
        name = "Add",
        defaultWidth = 24.dp,
        defaultHeight = 24.dp,
        viewportWidth = 24f,
        viewportHeight = 24f
    ).apply {
        path(
            fill = SolidColor(Color.Black),
            pathFillType = PathFillType.NonZero
        ) {
            moveTo(19f, 13f)
            horizontalLineTo(13f)
            verticalLineTo(19f)
            horizontalLineTo(11f)
            verticalLineTo(13f)
            horizontalLineTo(5f)
            verticalLineTo(11f)
            horizontalLineTo(11f)
            verticalLineTo(5f)
            horizontalLineTo(13f)
            verticalLineTo(11f)
            horizontalLineTo(19f)
            close()
        }
    }.build()

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

private val ImportFileIcon: ImageVector
    get() = ImageVector.Builder(
        name = "ImportFile",
        defaultWidth = 24.dp,
        defaultHeight = 24.dp,
        viewportWidth = 24f,
        viewportHeight = 24f
    ).apply {
        path(
            fill = SolidColor(Color.Black),
            pathFillType = PathFillType.NonZero
        ) {
            moveTo(14f, 2f)
            horizontalLineTo(6f)
            curveTo(4.9f, 2f, 4f, 2.9f, 4f, 4f)
            verticalLineTo(20f)
            curveTo(4f, 21.1f, 4.9f, 22f, 6f, 22f)
            horizontalLineTo(18f)
            curveTo(19.1f, 22f, 20f, 21.1f, 20f, 20f)
            verticalLineTo(8f)
            close()
            moveTo(13f, 9f)
            verticalLineTo(3.5f)
            lineTo(18.5f, 9f)
            close()
            moveTo(13f, 17f)
            verticalLineTo(14f)
            horizontalLineTo(8f)
            verticalLineTo(12f)
            horizontalLineTo(13f)
            verticalLineTo(9f)
            lineTo(17f, 13f)
            close()
        }
    }.build()

private val SettingsIcon: ImageVector
    get() = ImageVector.Builder(
        name = "Settings",
        defaultWidth = 24.dp,
        defaultHeight = 24.dp,
        viewportWidth = 24f,
        viewportHeight = 24f
    ).apply {
        path(
            fill = SolidColor(Color.Black),
            pathFillType = PathFillType.NonZero
        ) {
            moveTo(19.43f, 12.98f)
            curveTo(19.47f, 12.66f, 19.5f, 12.34f, 19.5f, 12f)
            curveTo(19.5f, 11.66f, 19.47f, 11.33f, 19.42f, 11.02f)
            lineTo(21.54f, 9.37f)
            curveTo(21.73f, 9.22f, 21.78f, 8.95f, 21.66f, 8.73f)
            lineTo(19.66f, 5.27f)
            curveTo(19.54f, 5.05f, 19.28f, 4.96f, 19.05f, 5.05f)
            lineTo(16.56f, 6.05f)
            curveTo(16.04f, 5.65f, 15.5f, 5.32f, 14.87f, 5.07f)
            lineTo(14.5f, 2.42f)
            curveTo(14.46f, 2.18f, 14.25f, 2f, 14f, 2f)
            horizontalLineTo(10f)
            curveTo(9.75f, 2f, 9.54f, 2.18f, 9.5f, 2.42f)
            lineTo(9.12f, 5.07f)
            curveTo(8.5f, 5.32f, 7.96f, 5.66f, 7.44f, 6.05f)
            lineTo(4.95f, 5.05f)
            curveTo(4.72f, 4.96f, 4.46f, 5.05f, 4.34f, 5.27f)
            lineTo(2.34f, 8.73f)
            curveTo(2.21f, 8.95f, 2.27f, 9.22f, 2.46f, 9.37f)
            lineTo(4.58f, 11.02f)
            curveTo(4.53f, 11.34f, 4.5f, 11.67f, 4.5f, 12f)
            curveTo(4.5f, 12.33f, 4.53f, 12.66f, 4.58f, 12.98f)
            lineTo(2.46f, 14.63f)
            curveTo(2.27f, 14.78f, 2.21f, 15.05f, 2.34f, 15.27f)
            lineTo(4.34f, 18.73f)
            curveTo(4.46f, 18.95f, 4.72f, 19.04f, 4.95f, 18.95f)
            lineTo(7.44f, 17.95f)
            curveTo(7.96f, 18.35f, 8.5f, 18.68f, 9.13f, 18.93f)
            lineTo(9.5f, 21.58f)
            curveTo(9.54f, 21.82f, 9.75f, 22f, 10f, 22f)
            horizontalLineTo(14f)
            curveTo(14.25f, 22f, 14.46f, 21.82f, 14.5f, 21.58f)
            lineTo(14.88f, 18.93f)
            curveTo(15.5f, 18.68f, 16.04f, 18.34f, 16.56f, 17.95f)
            lineTo(19.05f, 18.95f)
            curveTo(19.28f, 19.04f, 19.54f, 18.95f, 19.66f, 18.73f)
            lineTo(21.66f, 15.27f)
            curveTo(21.78f, 15.05f, 21.73f, 14.78f, 21.54f, 14.63f)
            close()
            moveTo(12f, 15.5f)
            curveTo(10.07f, 15.5f, 8.5f, 13.93f, 8.5f, 12f)
            curveTo(8.5f, 10.07f, 10.07f, 8.5f, 12f, 8.5f)
            curveTo(13.93f, 8.5f, 15.5f, 10.07f, 15.5f, 12f)
            curveTo(15.5f, 13.93f, 13.93f, 15.5f, 12f, 15.5f)
            close()
        }
    }.build()

private val DeleteIcon: ImageVector
    get() = ImageVector.Builder(
        name = "Delete",
        defaultWidth = 24.dp,
        defaultHeight = 24.dp,
        viewportWidth = 24f,
        viewportHeight = 24f
    ).apply {
        path(
            fill = SolidColor(Color.Black),
            pathFillType = PathFillType.NonZero
        ) {
            moveTo(6f, 19f)
            curveTo(6f, 20.1f, 6.9f, 21f, 8f, 21f)
            horizontalLineTo(16f)
            curveTo(17.1f, 21f, 18f, 20.1f, 18f, 19f)
            verticalLineTo(7f)
            horizontalLineTo(6f)
            close()
            moveTo(8f, 9f)
            horizontalLineTo(16f)
            verticalLineTo(19f)
            horizontalLineTo(8f)
            close()
            moveTo(15.5f, 4f)
            lineTo(14.5f, 3f)
            horizontalLineTo(9.5f)
            lineTo(8.5f, 4f)
            horizontalLineTo(5f)
            verticalLineTo(6f)
            horizontalLineTo(19f)
            verticalLineTo(4f)
            close()
        }
    }.build()
