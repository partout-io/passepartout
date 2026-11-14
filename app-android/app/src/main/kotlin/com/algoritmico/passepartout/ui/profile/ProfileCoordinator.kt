// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.observables.ProfileEditor
import com.algoritmico.passepartout.ui.LocalProfileObservable
import com.algoritmico.passepartout.ui.alerts.GenericErrorAlert
import com.algoritmico.passepartout.ui.extensions.titleText
import com.algoritmico.passepartout.ui.profile.modules.OpenVPNCredentialsView
import com.algoritmico.passepartout.ui.theme.*
import io.partout.extensions.moduleId
import io.partout.extensions.moduleType
import io.partout.models.*

private sealed interface ProfileDestination {
    data object Overview : ProfileDestination
    data class Module(val module: TaggedModule) : ProfileDestination
    data class Credentials(val module: TaggedModuleOpenVPN) : ProfileDestination
    data class Content(val content: ProfileEditor.Content) : ProfileDestination
}

@Composable
fun ProfileCoordinator(editor: ProfileEditor, onDismiss: () -> Unit) {
    val profiles = LocalProfileObservable.current
    val draft by editor.state.collectAsStateWithLifecycle()
    val content = editor.content.collectAsStateWithLifecycle().value
    val isSaving by profiles.editorSaving.collectAsStateWithLifecycle()
    val saveError by profiles.editorError.collectAsStateWithLifecycle()
    val visibleModules = draft.modules.filterNot { it is TaggedModuleCustom }

    var selectedModuleIndex by rememberSaveable { mutableStateOf<Int?>(null) }
    var showsCredentials by rememberSaveable(selectedModuleIndex) { mutableStateOf(false) }
    val selectedModule = selectedModuleIndex?.let(visibleModules::getOrNull)
    val destination = when {
        content != null -> ProfileDestination.Content(content)
        showsCredentials && selectedModule is TaggedModuleOpenVPN -> ProfileDestination.Credentials(selectedModule)
        selectedModule != null -> ProfileDestination.Module(selectedModule)
        else -> ProfileDestination.Overview
    }
    val isOverview = destination == ProfileDestination.Overview
    val canSave = !isSaving && draft.name.isNotBlank() && editor.isDirty
    val title = when (destination) {
        ProfileDestination.Overview -> stringResource(R.string.global_nouns_profile)
        is ProfileDestination.Module -> destination.module.moduleType.titleText()
        is ProfileDestination.Credentials -> stringResource(R.string.modules_openvpn_credentials)
        is ProfileDestination.Content -> destination.content.title
    }

    fun back() {
        if (isSaving) return
        when (destination) {
            ProfileDestination.Overview -> onDismiss()
            is ProfileDestination.Module -> selectedModuleIndex = null
            is ProfileDestination.Credentials -> showsCredentials = false
            is ProfileDestination.Content -> editor.closeContent()
        }
    }

    Dialog(onDismissRequest = { back() }, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        BackHandler { back() }
        saveError?.let { GenericErrorAlert(error = it, onDismiss = profiles::clearEditorError) }
        Scaffold(
            topBar = {
                ProfileToolbar(
                    title = title,
                    isOverview = isOverview,
                    isSaving = isSaving,
                    canSave = canSave,
                    onBack = { back() },
                    onSave = profiles::saveEditor
                )
            }
        ) { padding ->
            // Reset list position between destinations, but not when draft fields change.
            key(selectedModuleIndex, showsCredentials, content?.title) {
                val modifier = Modifier.padding(padding).imePadding()
                when (destination) {
                    ProfileDestination.Overview -> ProfileOverview(
                        draft = draft,
                        modules = visibleModules,
                        isSaving = isSaving,
                        onRename = editor::rename,
                        onSelectModule = { selectedModuleIndex = it },
                        modifier = modifier
                    )
                    else -> ThemeList(modifier = modifier) {
                        item {
                            when (destination) {
                                is ProfileDestination.Module -> ModuleDetailView(
                                    module = destination.module,
                                    onOpenContent = editor::openContent,
                                    onCredentials = { showsCredentials = true }
                                )
                                is ProfileDestination.Credentials -> OpenVPNCredentialsView(
                                    module = destination.module.value,
                                    onChange = { editor.updateModule(destination.module.copy(value = it)) }
                                )
                                is ProfileDestination.Content -> ThemeLongContent(destination.content.text)
                                ProfileDestination.Overview -> Unit
                            }
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ProfileToolbar(
    title: String,
    isOverview: Boolean,
    isSaving: Boolean,
    canSave: Boolean,
    onBack: () -> Unit,
    onSave: () -> Unit
) {
    TopAppBar(
        title = { Text(title) },
        navigationIcon = {
            if (!isOverview) {
                IconButton(onClick = onBack, enabled = !isSaving) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, stringResource(R.string.global_actions_back))
                }
            }
        },
        actions = {
            if (isOverview) {
                TextButton(enabled = canSave, onClick = onSave) {
                    Text(stringResource(R.string.global_actions_save))
                }
                IconButton(onClick = onBack, enabled = !isSaving) {
                    Icon(Icons.Default.Close, stringResource(R.string.global_actions_cancel))
                }
            }
        }
    )
}

@Composable
private fun ProfileOverview(
    draft: TaggedProfile,
    modules: List<TaggedModule>,
    isSaving: Boolean,
    onRename: (String) -> Unit,
    onSelectModule: (Int) -> Unit,
    modifier: Modifier
) {
    val theme = LocalTheme.current
    val modulesTitle = stringResource(R.string.global_nouns_modules)
    ThemeList(modifier = modifier) {
        if (isSaving) item { LinearProgressIndicator(Modifier.fillMaxWidth()) }
        item {
            ThemeTextField(
                value = draft.name,
                onValueChange = onRename,
                enabled = !isSaving,
                label = stringResource(R.string.global_nouns_name),
                modifier = Modifier.padding(theme.spacing.large)
            )
        }
        themeListSection(header = modulesTitle) {
            itemsIndexed(modules) { index, module ->
                ProfileModuleRow(
                    module = module,
                    isActive = module.moduleId in draft.activeModulesIds,
                    isSaving = isSaving,
                    onClick = { onSelectModule(index) }
                )
            }
        }
    }
}

@Composable
private fun ProfileModuleRow(module: TaggedModule, isActive: Boolean, isSaving: Boolean, onClick: () -> Unit) {
    val title = module.moduleType.titleText()
    val status = stringResource(
        if (isActive) R.string.entities_tunnel_status_active else R.string.entities_tunnel_status_inactive
    )
    val canOpenModule = module !is TaggedModuleOnDemand && !isSaving
    if (canOpenModule) {
        ThemeNavigatingButton(title = title, trailingText = status, onClick = onClick)
    } else {
        ListItem(headlineContent = { Text(title) }, trailingContent = { ThemeTrailingValue(status) })
    }
}
