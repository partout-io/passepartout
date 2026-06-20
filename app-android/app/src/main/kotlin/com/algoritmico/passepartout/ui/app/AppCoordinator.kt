// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.app

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.observables.ErrorHandler
import com.algoritmico.passepartout.observables.ProfileObservable
import com.algoritmico.passepartout.ui.LocalErrorHandler
import com.algoritmico.passepartout.ui.LocalProfileObservable
import com.algoritmico.passepartout.ui.settings.SettingsCoordinator
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.ThemeImage
import com.algoritmico.passepartout.ui.theme.ThemeImageName
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

@Composable
fun AppCoordinator(
    logTag: String,
    title: String,
    profileContainerStyle: ProfileContainerStyle = ProfileContainerStyle.list,
    onImportProfile: () -> Unit
) {
    val state = rememberAppCoordinatorState(logTag)

    BackHandler(enabled = state.isContextualMode) {
        state.clearContextualMode()
    }

    AppCoordinatorScaffold(
        title = title,
        state = state,
        onImportProfile = onImportProfile
    ) { modifier ->
        ProfileContainerView(
            modifier = modifier,
            style = profileContainerStyle,
            contextualSelection = state.profileContextualSelection,
            onImportProfile = onImportProfile
        )
    }

    if (state.isSettingsPresented) {
        SettingsCoordinator(
            onDismissRequest = state::dismissSettings
        )
    }
}

@Composable
private fun rememberAppCoordinatorState(
    logTag: String
): AppCoordinatorState {
    val contextualProfileIds = rememberSaveable {
        mutableStateOf(emptyList<String>())
    }
    val isSettingsPresented = rememberSaveable {
        mutableStateOf(false)
    }
    val coroutineScope = rememberCoroutineScope()
    val profileObservable = LocalProfileObservable.current
    val errorHandler = LocalErrorHandler.current

    return remember(logTag, coroutineScope, profileObservable, errorHandler) {
        AppCoordinatorState(
            logTag = logTag,
            contextualProfileIdsState = contextualProfileIds,
            isSettingsPresentedState = isSettingsPresented,
            coroutineScope = coroutineScope,
            profileObservable = profileObservable,
            errorHandler = errorHandler
        )
    }
}

private class AppCoordinatorState(
    private val logTag: String,
    private val contextualProfileIdsState: MutableState<List<String>>,
    private val isSettingsPresentedState: MutableState<Boolean>,
    private val coroutineScope: CoroutineScope,
    private val profileObservable: ProfileObservable,
    private val errorHandler: ErrorHandler
) {
    val contextualProfileIds: List<String>
        get() = contextualProfileIdsState.value

    val isSettingsPresented: Boolean
        get() = isSettingsPresentedState.value

    val isContextualMode: Boolean
        get() = contextualProfileIds.isNotEmpty()

    val contextualProfileCount: Int
        get() = contextualProfileIds.size

    val profileContextualSelection: ProfileContextualSelection
        get() = ProfileContextualSelection(
            profileIds = contextualProfileIds,
            onProfileSelected = ::toggleContextualProfile,
            onProfileAction = ::addContextualProfile
        )

    fun clearContextualMode() {
        contextualProfileIdsState.value = emptyList()
    }

    fun toggleContextualProfile(profileId: String) {
        val updatedProfileIds = if (profileId in contextualProfileIds) {
            contextualProfileIds - profileId
        } else {
            contextualProfileIds + profileId
        }
        contextualProfileIdsState.value = updatedProfileIds
    }

    fun addContextualProfile(profileId: String) {
        if (profileId !in contextualProfileIds) {
            contextualProfileIdsState.value = contextualProfileIds + profileId
        }
    }

    fun deleteContextualProfiles() {
        val profileIds = contextualProfileIds
        clearContextualMode()
        coroutineScope.launch {
            runCatchingNonFatal {
                profileObservable.remove(profileIds)
            }.onFailure {
                AppLog.e(logTag, "Unable to delete profiles", it)
                errorHandler.report(it)
            }
        }
    }

    fun presentSettings() {
        isSettingsPresentedState.value = true
    }

    fun dismissSettings() {
        isSettingsPresentedState.value = false
    }
}

@Composable
private fun AppCoordinatorScaffold(
    title: String,
    state: AppCoordinatorState,
    onImportProfile: () -> Unit,
    content: @Composable (Modifier) -> Unit
) {
    AppCoordinatorScaffold(
        title = title,
        contextualProfileCount = state.contextualProfileCount,
        onClearContextualMode = state::clearContextualMode,
        onDeleteProfiles = state::deleteContextualProfiles,
        onSettings = state::presentSettings,
        onImportProfile = onImportProfile,
        content = content
    )
}

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
            AppCoordinatorTopBar(
                title = title,
                contextualProfileCount = contextualProfileCount,
                onClearContextualMode = onClearContextualMode,
                onDeleteProfiles = onDeleteProfiles,
                onSettings = onSettings
            )
        },
        floatingActionButton = {
            if (!isContextualMode) {
                AddProfileButton(
                    onClick = {
                        isAddSheetPresented = true
                    }
                )
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
        ImportProfileSheet(
            onDismissRequest = {
                isAddSheetPresented = false
            },
            onImportProfile = {
                isAddSheetPresented = false
                onImportProfile()
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AppCoordinatorTopBar(
    title: String,
    contextualProfileCount: Int,
    onClearContextualMode: () -> Unit,
    onDeleteProfiles: () -> Unit,
    onSettings: () -> Unit
) {
    val isContextualMode = contextualProfileCount > 0

    TopAppBar(
        title = {
            AppCoordinatorTitle(
                title = title,
                contextualProfileCount = contextualProfileCount
            )
        },
        navigationIcon = {
            if (isContextualMode) {
                IconButton(
                    onClick = onClearContextualMode
                ) {
                    ThemeImage(
                        name = ThemeImageName.close,
                        contentDescription = "Cancel"
                    )
                }
            }
        },
        actions = {
            AppCoordinatorActions(
                isContextualMode = isContextualMode,
                onDeleteProfiles = onDeleteProfiles,
                onSettings = onSettings
            )
        }
    )
}

@Composable
private fun AppCoordinatorTitle(
    title: String,
    contextualProfileCount: Int
) {
    if (contextualProfileCount > 0) {
        Text("$contextualProfileCount selected")
    } else {
        Text(title)
    }
}

@Composable
private fun AppCoordinatorActions(
    isContextualMode: Boolean,
    onDeleteProfiles: () -> Unit,
    onSettings: () -> Unit
) {
    if (isContextualMode) {
        IconButton(
            onClick = onDeleteProfiles
        ) {
            ThemeImage(
                name = ThemeImageName.contextRemove,
                contentDescription = "Delete profiles"
            )
        }
    } else {
        IconButton(
            onClick = onSettings
        ) {
            ThemeImage(
                name = ThemeImageName.settings,
                contentDescription = "Settings"
            )
        }
    }
}

@Composable
private fun AddProfileButton(
    onClick: () -> Unit
) {
    FloatingActionButton(
        onClick = onClick
    ) {
        ThemeImage(
            name = ThemeImageName.add,
            contentDescription = "Add profile"
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ImportProfileSheet(
    onDismissRequest: () -> Unit,
    onImportProfile: () -> Unit
) {
    val theme = LocalTheme.current

    ModalBottomSheet(
        onDismissRequest = onDismissRequest
    ) {
        ListItem(
            headlineContent = {
                Text("Import file")
            },
            leadingContent = {
                ThemeImage(
                    name = ThemeImageName.profileImportFile,
                    contentDescription = null
                )
            },
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onImportProfile)
                .padding(bottom = theme.spacing.xxLarge)
        )
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
