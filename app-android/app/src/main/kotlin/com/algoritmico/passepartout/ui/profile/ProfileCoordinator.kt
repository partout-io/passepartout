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
import com.algoritmico.passepartout.ui.profile.modules.OpenVPNCredentialsView
import com.algoritmico.passepartout.observables.ProfileEditor
import com.algoritmico.passepartout.ui.extensions.titleText
import com.algoritmico.passepartout.ui.LocalProfileObservable
import com.algoritmico.passepartout.ui.alerts.GenericErrorAlert
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.ThemeTextField
import com.algoritmico.passepartout.ui.theme.ThemeList
import com.algoritmico.passepartout.ui.theme.ThemeLongContent
import com.algoritmico.passepartout.ui.theme.ThemeNavigatingButton
import com.algoritmico.passepartout.ui.theme.ThemeTrailingValue
import com.algoritmico.passepartout.ui.theme.themeListSection
import io.partout.extensions.moduleId
import io.partout.extensions.moduleType
import io.partout.models.TaggedModuleCustom
import io.partout.models.TaggedModuleOnDemand
import io.partout.models.TaggedModuleOpenVPN

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileCoordinator(editor: ProfileEditor, onDismiss: () -> Unit) {
    val theme = LocalTheme.current
    val modulesTitle = stringResource(R.string.global_nouns_modules)
    val draft by editor.state.collectAsStateWithLifecycle()
    val profiles = LocalProfileObservable.current
    val content = editor.content.collectAsStateWithLifecycle().value
    var moduleIndex by rememberSaveable { mutableStateOf<Int?>(null) }
    var showsCredentials by rememberSaveable(moduleIndex) { mutableStateOf(false) }
    val saving by profiles.editorSaving.collectAsStateWithLifecycle()
    val saveError by profiles.editorError.collectAsStateWithLifecycle()
    val module = moduleIndex?.let(draft.modules::getOrNull)
    val moduleType = module?.moduleType ?: (module as? TaggedModuleCustom)?.value?.innerType
    fun back() {
        if (saving) return
        when {
            content != null -> editor.closeContent()
            showsCredentials -> showsCredentials = false
            moduleIndex != null -> moduleIndex = null
            else -> onDismiss()
        }
    }
    Dialog(onDismissRequest = ::back, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        BackHandler { back() }
        saveError?.let { error ->
            GenericErrorAlert(error = error, onDismiss = profiles::clearEditorError)
        }
        Scaffold(
            topBar = {
                TopAppBar(
                    title = {
                        Text(if (showsCredentials) stringResource(R.string.modules_openvpn_credentials)
                            else content?.title ?: moduleType?.titleText() ?: stringResource(R.string.global_nouns_profile))
                    },
                    navigationIcon = {
                        if (module != null) {
                            IconButton(onClick = ::back, enabled = !saving) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                    contentDescription = stringResource(R.string.global_actions_back)
                                )
                            }
                        }
                    },
                    actions = {
                        if (module == null) {
                            TextButton(
                                enabled = !saving && draft.name.isNotBlank() && editor.isDirty,
                                onClick = profiles::saveEditor
                            ) { Text(stringResource(R.string.global_actions_save)) }
                            IconButton(onClick = ::back, enabled = !saving) {
                                Icon(
                                    imageVector = Icons.Default.Close,
                                    contentDescription = stringResource(R.string.global_actions_cancel)
                                )
                            }
                        }
                    }
                )
            }
        ) { padding ->
            key(moduleIndex, showsCredentials, content?.title) {
                ThemeList(modifier = Modifier.padding(padding).imePadding()) {
                    if (saving) item { LinearProgressIndicator(Modifier.fillMaxWidth()) }
                    if (content != null) {
                        item {
                            ThemeLongContent(content.text)
                        }
                    } else if (showsCredentials && module is TaggedModuleOpenVPN) {
                        item {
                            OpenVPNCredentialsView(module = module.value, onChange = {
                                editor.updateModule(module.copy(value = it))
                            })
                        }
                    } else if (module == null) {
                        item {
                            ThemeTextField(
                                value = draft.name,
                                onValueChange = editor::rename,
                                enabled = !saving,
                                label = stringResource(R.string.global_nouns_name),
                                modifier = Modifier.padding(theme.spacing.large)
                            )
                        }
                        themeListSection(header = modulesTitle) {
                            itemsIndexed(draft.modules) { index, item ->
                                val title = (item.moduleType ?: (item as? TaggedModuleCustom)?.value?.innerType).titleText()
                                val status = stringResource(if (item.moduleId in draft.activeModulesIds)
                                    R.string.entities_tunnel_status_active else R.string.entities_tunnel_status_inactive)
                                if (item !is TaggedModuleOnDemand && !saving) {
                                    ThemeNavigatingButton(title = title, trailingText = status,
                                        onClick = { moduleIndex = index })
                                } else {
                                    ListItem(headlineContent = { Text(title) },
                                        trailingContent = { ThemeTrailingValue(status) })
                                }
                            }
                        }
                    } else {
                        item {
                            ModuleDetailView(module, onOpenContent = editor::openContent,
                                onCredentials = { showsCredentials = true })
                        }
                    }
                }
            }
        }
    }
}
