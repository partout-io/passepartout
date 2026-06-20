// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.app

import android.content.res.Configuration
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
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
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
import androidx.compose.ui.platform.LocalConfiguration
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
    val state = rememberAppCoordinatorState(logTag, profileContainerStyle)
    val isTablet = isTablet()
    val selectedProfileContainerStyle = if (isTablet) {
        state.profileContainerStyle
    } else {
        ProfileContainerStyle.list
    }

    BackHandler(enabled = state.isContextualMode) {
        state.clearContextualMode()
    }

    AppCoordinatorScaffold(
        title = title,
        state = state,
        profileContainerStyle = selectedProfileContainerStyle,
        isProfileContainerStylePickerVisible = isTablet,
        onImportProfile = onImportProfile
    ) { modifier ->
        ProfileContainerView(
            modifier = modifier,
            style = selectedProfileContainerStyle,
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
    logTag: String,
    profileContainerStyle: ProfileContainerStyle
): AppCoordinatorState {
    val contextualProfileIds = rememberSaveable {
        mutableStateOf(emptyList<String>())
    }
    val isSettingsPresented = rememberSaveable {
        mutableStateOf(false)
    }
    val profileContainerStyleState = rememberSaveable(profileContainerStyle) {
        mutableStateOf(profileContainerStyle)
    }
    val coroutineScope = rememberCoroutineScope()
    val profileObservable = LocalProfileObservable.current
    val errorHandler = LocalErrorHandler.current

    return remember(
        logTag,
        profileContainerStyleState,
        coroutineScope,
        profileObservable,
        errorHandler
    ) {
        AppCoordinatorState(
            logTag = logTag,
            contextualProfileIdsState = contextualProfileIds,
            isSettingsPresentedState = isSettingsPresented,
            profileContainerStyleState = profileContainerStyleState,
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
    private val profileContainerStyleState: MutableState<ProfileContainerStyle>,
    private val coroutineScope: CoroutineScope,
    private val profileObservable: ProfileObservable,
    private val errorHandler: ErrorHandler
) {
    val contextualProfileIds: List<String>
        get() = contextualProfileIdsState.value

    val isSettingsPresented: Boolean
        get() = isSettingsPresentedState.value

    val profileContainerStyle: ProfileContainerStyle
        get() = profileContainerStyleState.value

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

    fun selectProfileContainerStyle(style: ProfileContainerStyle) {
        profileContainerStyleState.value = style
    }
}

@Composable
private fun AppCoordinatorScaffold(
    title: String,
    state: AppCoordinatorState,
    profileContainerStyle: ProfileContainerStyle,
    isProfileContainerStylePickerVisible: Boolean,
    onImportProfile: () -> Unit,
    content: @Composable (Modifier) -> Unit
) {
    AppCoordinatorScaffold(
        title = title,
        contextualProfileCount = state.contextualProfileCount,
        profileContainerStyle = profileContainerStyle,
        isProfileContainerStylePickerVisible = isProfileContainerStylePickerVisible,
        onClearContextualMode = state::clearContextualMode,
        onDeleteProfiles = state::deleteContextualProfiles,
        onProfileContainerStyle = state::selectProfileContainerStyle,
        onSettings = state::presentSettings,
        onImportProfile = onImportProfile,
        content = content
    )
}

@Composable
private fun AppCoordinatorScaffold(
    title: String,
    contextualProfileCount: Int,
    profileContainerStyle: ProfileContainerStyle = ProfileContainerStyle.list,
    isProfileContainerStylePickerVisible: Boolean = false,
    onClearContextualMode: () -> Unit,
    onDeleteProfiles: () -> Unit,
    onProfileContainerStyle: (ProfileContainerStyle) -> Unit = {},
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
                profileContainerStyle = profileContainerStyle,
                isProfileContainerStylePickerVisible = isProfileContainerStylePickerVisible,
                onClearContextualMode = onClearContextualMode,
                onDeleteProfiles = onDeleteProfiles,
                onProfileContainerStyle = onProfileContainerStyle,
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
    profileContainerStyle: ProfileContainerStyle,
    isProfileContainerStylePickerVisible: Boolean,
    onClearContextualMode: () -> Unit,
    onDeleteProfiles: () -> Unit,
    onProfileContainerStyle: (ProfileContainerStyle) -> Unit,
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
                profileContainerStyle = profileContainerStyle,
                isProfileContainerStylePickerVisible = isProfileContainerStylePickerVisible,
                onDeleteProfiles = onDeleteProfiles,
                onProfileContainerStyle = onProfileContainerStyle,
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
    profileContainerStyle: ProfileContainerStyle,
    isProfileContainerStylePickerVisible: Boolean,
    onDeleteProfiles: () -> Unit,
    onProfileContainerStyle: (ProfileContainerStyle) -> Unit,
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
        if (isProfileContainerStylePickerVisible) {
            ProfileContainerStylePicker(
                selectedStyle = profileContainerStyle,
                onStyleSelected = onProfileContainerStyle
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ProfileContainerStylePicker(
    selectedStyle: ProfileContainerStyle,
    onStyleSelected: (ProfileContainerStyle) -> Unit
) {
    val styles = ProfileContainerStyle.entries

    SingleChoiceSegmentedButtonRow {
        styles.forEachIndexed { index, style ->
            SegmentedButton(
                selected = style == selectedStyle,
                onClick = {
                    onStyleSelected(style)
                },
                shape = SegmentedButtonDefaults.itemShape(
                    index = index,
                    count = styles.size
                ),
                icon = {}
            ) {
                ThemeImage(
                    name = style.imageName,
                    contentDescription = style.contentDescription
                )
            }
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

@Composable
private fun isTablet(): Boolean {
    return LocalConfiguration.current.isTablet
}

private val Configuration.isTablet: Boolean
    get() {
        val screenSize = screenLayout and Configuration.SCREENLAYOUT_SIZE_MASK
        return screenSize >= Configuration.SCREENLAYOUT_SIZE_LARGE
    }

private val ProfileContainerStyle.imageName: ThemeImageName
    get() {
        return when (this) {
            ProfileContainerStyle.list -> ThemeImageName.profilesList
            ProfileContainerStyle.grid -> ThemeImageName.profilesGrid
        }
    }

private val ProfileContainerStyle.contentDescription: String
    get() {
        return when (this) {
            ProfileContainerStyle.list -> "List profiles"
            ProfileContainerStyle.grid -> "Grid profiles"
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

@Preview(showBackground = true, widthDp = 840, heightDp = 852)
@Composable
private fun AppCoordinatorTabletPreview() {
    MaterialTheme {
        AppCoordinatorScaffold(
            title = "Passepartout",
            contextualProfileCount = 0,
            profileContainerStyle = ProfileContainerStyle.grid,
            isProfileContainerStylePickerVisible = true,
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
