// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import io.partout.extensions.interactiveModule
import io.partout.extensions.isInteractive
import io.partout.extensions.withInteractiveOpenVPNCredentials
import io.partout.models.OpenVPNConfiguration
import io.partout.models.OpenVPNCredentials
import io.partout.models.OpenVPNCredentialsOTPMethod
import io.partout.models.OpenVPNModule
import io.partout.models.TaggedModuleOpenVPN
import io.partout.models.TaggedProfile
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ProfileExtensionsUnitTest {
    @Test
    fun withInteractiveOpenVPNCredentials_preservesInteractiveModuleFlags() {
        val profile = openVPNProfile(
            module = OpenVPNModule(
                id = MODULE_ID,
                configuration = OpenVPNConfiguration(
                    authUserPass = true,
                    staticChallenge = true
                ),
                requiresInteractiveCredentials = true
            )
        )

        val updated = profile.withInteractiveOpenVPNCredentials(
            username = "username",
            password = ""
        )
        val module = updated.interactiveOpenVPNModule()

        assertNotNull(module)
        assertTrue(updated.isInteractive)
        assertEquals(true, module?.configuration?.staticChallenge)
        assertEquals(true, module?.requiresInteractiveCredentials)
        assertEquals("username", module?.credentials?.username)
        assertEquals("", module?.credentials?.password)
        assertEquals(OpenVPNCredentialsOTPMethod.none, module?.credentials?.otpMethod)
    }

    @Test
    fun withInteractiveOpenVPNCredentials_encodesOTPForAuthentication() {
        val profile = openVPNProfile(
            module = OpenVPNModule(
                id = MODULE_ID,
                configuration = OpenVPNConfiguration(
                    authUserPass = true,
                    staticChallenge = true
                ),
                credentials = OpenVPNCredentials(
                    username = "saved-username",
                    password = "saved-password",
                    otpMethod = OpenVPNCredentialsOTPMethod.append
                ),
                requiresInteractiveCredentials = true
            )
        )

        val updated = profile.withInteractiveOpenVPNCredentials(
            username = "ignored-username",
            password = "ignored-password",
            otp = "123456"
        )
        val credentials = updated.interactiveOpenVPNModule()?.credentials

        assertEquals("saved-username", credentials?.username)
        assertEquals("saved-password123456", credentials?.password)
        assertEquals(OpenVPNCredentialsOTPMethod.none, credentials?.otpMethod)
        assertEquals(null, credentials?.otp)
    }

    @Test
    fun withInteractiveOpenVPNCredentials_encodesSCRV1OTPForAuthentication() {
        val profile = openVPNProfile(
            module = OpenVPNModule(
                id = MODULE_ID,
                configuration = OpenVPNConfiguration(
                    authUserPass = true,
                    staticChallenge = true
                ),
                credentials = OpenVPNCredentials(
                    username = "saved-username",
                    password = "saved-password",
                    otpMethod = OpenVPNCredentialsOTPMethod.encode
                ),
                requiresInteractiveCredentials = true
            )
        )

        val updated = profile.withInteractiveOpenVPNCredentials(
            username = "ignored-username",
            password = "ignored-password",
            otp = "123456"
        )
        val credentials = updated.interactiveOpenVPNModule()?.credentials

        assertEquals("saved-username", credentials?.username)
        assertEquals("SCRV1:c2F2ZWQtcGFzc3dvcmQ=:MTIzNDU2", credentials?.password)
        assertEquals(OpenVPNCredentialsOTPMethod.none, credentials?.otpMethod)
        assertEquals(null, credentials?.otp)
    }

    @Test
    fun withInteractiveOpenVPNCredentials_serializesTaggedModuleValue() {
        val profile = openVPNProfile(
            module = OpenVPNModule(
                id = MODULE_ID,
                configuration = OpenVPNConfiguration(
                    authUserPass = true,
                    staticChallenge = true
                ),
                requiresInteractiveCredentials = true
            )
        )

        val updated = profile.withInteractiveOpenVPNCredentials(
            username = "username",
            password = ""
        )
        val json = tunnelJson.encodeToString(updated)

        assertTrue(json.contains("\"type\":\"OpenVPN\""))
        assertTrue(json.contains("\"value\":{\"id\":\"$MODULE_ID\""))
        assertFalse(json.contains("\"type\":\"OpenVPN\",\"id\":\"$MODULE_ID\""))
    }

    private fun openVPNProfile(module: OpenVPNModule) = TaggedProfile(
        activeModulesIds = setOf(module.id),
        id = "profile-id",
        modules = listOf(TaggedModuleOpenVPN(module)),
        name = "Profile"
    )

    private fun TaggedProfile.interactiveOpenVPNModule(): OpenVPNModule? {
        val tagged = interactiveModule
        require(tagged is TaggedModuleOpenVPN)
        return tagged.value
    }

    private companion object {
        const val MODULE_ID = "module-id"

        val tunnelJson = Json {
            ignoreUnknownKeys = true
        }
    }
}
