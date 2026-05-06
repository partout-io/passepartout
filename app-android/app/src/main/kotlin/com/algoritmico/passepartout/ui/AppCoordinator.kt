// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppCoordinator(
    title: String,
    profiles: List<ProfileItemUiState>,
    selectedProfileId: String?,
    onProfileSelected: (String) -> Unit,
    onProfileToggle: (String, Boolean) -> Unit,
    onProfilesDelete: (Array<String>) -> Unit,
    onImportProfile: () -> Unit
) {
    var contextualProfileIds by rememberSaveable {
        mutableStateOf(emptyList<String>())
    }
    val isContextualMode = contextualProfileIds.isNotEmpty()

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

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    if (isContextualMode) {
                        Text("${contextualProfileIds.size} selected")
                    } else {
                        Text(title)
                    }
                },
                navigationIcon = {
                    if (isContextualMode) {
                        IconButton(
                            onClick = {
                                clearContextualMode()
                            }
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
                            onClick = {
                                val profileIds = contextualProfileIds
                                clearContextualMode()
                                onProfilesDelete(profileIds.toTypedArray())
                            }
                        ) {
                            Icon(
                                imageVector = DeleteIcon,
                                contentDescription = "Delete profiles"
                            )
                        }
                    } else {
                        TextButton(onClick = onImportProfile) {
                            Text("Import profile")
                        }
                    }
                }
            )
        }
    ) { innerPadding ->
        ProfileContainerView(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            profiles = profiles,
            selectedProfileId = selectedProfileId,
            contextualProfileIds = contextualProfileIds,
            onProfileSelected = { profileId ->
                if (isContextualMode) {
                    toggleContextualProfile(profileId)
                } else {
                    onProfileSelected(profileId)
                }
            },
            onProfileToggle = onProfileToggle,
            onProfileContextualAction = { profileId ->
                if (profileId !in contextualProfileIds) {
                    contextualProfileIds = contextualProfileIds + profileId
                }
                onProfileSelected(profileId)
            },
            onImportProfile = onImportProfile
        )
    }
}

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
