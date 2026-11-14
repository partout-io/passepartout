// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0
package com.algoritmico.passepartout.observables

import io.partout.extensions.moduleId
import io.partout.models.TaggedModule
import io.partout.models.TaggedProfile
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

class ProfileEditor(profile: TaggedProfile) {
    data class Content(val title: String, val text: String)

    private val mutableContent = MutableStateFlow<Content?>(null)
    val content = mutableContent.asStateFlow()

    fun openContent(title: String, text: String) {
        mutableContent.value = Content(title, text)
    }

    fun closeContent() {
        mutableContent.value = null
    }

    private val original = profile
    private val mutableState = MutableStateFlow(profile)
    val state = mutableState.asStateFlow()
    val isDirty: Boolean get() = state.value != original

    fun rename(name: String) {
        mutableState.update { it.copy(name = name) }
    }

    fun updateModule(module: TaggedModule) {
        val id = module.moduleId ?: return
        mutableState.update { profile ->
            profile.copy(modules = profile.modules.map { if (it.moduleId == id) module else it })
        }
    }
}
