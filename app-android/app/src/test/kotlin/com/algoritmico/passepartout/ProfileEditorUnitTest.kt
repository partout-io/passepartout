// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0
package com.algoritmico.passepartout

import com.algoritmico.passepartout.observables.ProfileEditor
import io.partout.models.OpenVPNCredentials
import io.partout.models.OpenVPNCredentialsOTPMethod
import io.partout.models.OpenVPNModule
import io.partout.models.TaggedModuleOpenVPN
import io.partout.models.TaggedProfile
import org.junit.Assert.*
import org.junit.Test

class ProfileEditorUnitTest {
    private val credentials = OpenVPNCredentials("old", "secret", OpenVPNCredentialsOTPMethod.append, "123")
    private val module = TaggedModuleOpenVPN(OpenVPNModule("module", credentials = credentials,
        requiresInteractiveCredentials = true))
    private val profile = TaggedProfile("profile", "Original", listOf(module), setOf("module"))

    @Test
    fun renameLeavesOriginalAndModulesUntouched() {
        val editor = ProfileEditor(profile)
        editor.rename("Renamed")
        assertEquals("Original", profile.name)
        assertEquals(profile.copy(name = "Renamed"), editor.state.value)
        assertTrue(editor.isDirty)
        editor.rename("Original")
        assertFalse(editor.isDirty)
    }

    @Test
    fun credentialsPreserveOtherAuthenticationSettings() {
        val editor = ProfileEditor(profile)
        editor.credentials("module", "new", "password")
        val updated = editor.state.value.modules.single() as TaggedModuleOpenVPN
        assertEquals(module.value.copy(credentials = credentials.copy(username = "new", password = "password")), updated.value)
        assertEquals(credentials, module.value.credentials)
        assertEquals(profile.activeModulesIds, editor.state.value.activeModulesIds)
    }

    @Test
    fun missingModuleDoesNotChangeDraft() {
        val editor = ProfileEditor(profile)
        editor.credentials("missing", "new", "password")
        assertFalse(editor.isDirty)
    }
}
