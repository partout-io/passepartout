// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0
package com.algoritmico.passepartout.observables

import io.partout.extensions.moduleId
import io.partout.models.OpenVPNCredentials
import io.partout.models.OpenVPNCredentialsOTPMethod
import io.partout.models.TaggedModuleOpenVPN
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

    fun credentials(moduleId: String, username: String, password: String) {
        mutableState.update { profile ->
            profile.copy(modules = profile.modules.map { module ->
                if (module !is TaggedModuleOpenVPN || module.moduleId != moduleId) return@map module
                val credentials = module.value.credentials
                    ?: OpenVPNCredentials("", "", OpenVPNCredentialsOTPMethod.none)
                module.copy(value = module.value.copy(credentials = credentials.copy(
                    username = username,
                    password = password
                )))
            })
        }
    }
}
