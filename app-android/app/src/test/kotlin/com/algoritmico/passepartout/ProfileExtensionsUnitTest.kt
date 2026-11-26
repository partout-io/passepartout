// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.business.models.InteractiveLogin
import io.partout.extensions.encodedPassword
import io.partout.extensions.interactiveModule
import io.partout.extensions.isInteractive
import io.partout.extensions.withInteractiveLogin
import io.partout.models.IPModule
import io.partout.models.TaggedModule
import io.partout.models.TaggedModuleIP
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
    fun interactiveLogin_clearsEachPromptAndPreservesSavedOTPPassword() {
        for (method in OpenVPNCredentialsOTPMethod.entries) {
            val original = openVPNProfile(OpenVPNModule(
                id = MODULE_ID,
                requiresInteractiveCredentials = true,
                credentials = OpenVPNCredentials(username = "user", password = "saved-secret", otpMethod = method)
            ))
            val login = InteractiveLogin(original)
            assertEquals("", login.password)
            assertEquals("user", login.username)
            login.password = "123456"
            val prepared = login.connectionProfile().interactiveOpenVPNModule()
            val expected = if (method == OpenVPNCredentialsOTPMethod.none) {
                "123456"
            } else {
                method.encodedPassword("saved-secret", "123456")
            }
            assertEquals(expected, prepared?.credentials?.password)
            assertEquals("saved-secret", original.interactiveOpenVPNModule()?.credentials?.password)
            assertEquals("", InteractiveLogin(original).password)
        }
    }

    @Test
    fun interactiveLogin_keepsEnteredOTPSeparateFromOriginal() {
        val original = openVPNProfile(OpenVPNModule(
            id = MODULE_ID,
            requiresInteractiveCredentials = true,
            credentials = OpenVPNCredentials(
                username = "user", password = "secret", otpMethod = OpenVPNCredentialsOTPMethod.append
            )
        ))
        val login = InteractiveLogin(original)
        assertTrue(login.needsOTP)
        assertEquals("", login.password)
        login.password = "123456"
        val prepared = login.connectionProfile().interactiveOpenVPNModule()
        assertEquals("secret123456", prepared?.credentials?.password)
        assertEquals("secret", original.interactiveOpenVPNModule()?.credentials?.password)
        assertEquals(OpenVPNCredentialsOTPMethod.append, original.interactiveOpenVPNModule()?.credentials?.otpMethod)
    }

    @Test
    fun withInteractiveLogin_preservesInteractiveModuleFlags() {
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

        val updated = profile.withInteractiveLogin(
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
    fun withInteractiveLogin_encodesOTPForAuthentication() {
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

        val updated = profile.withInteractiveLogin(
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
    fun withInteractiveLogin_encodesSCRV1OTPForAuthentication() {
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

        val updated = profile.withInteractiveLogin(
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
    fun encodedPassword_preservesUTF8AndPadding() {
        assertEquals(
            "SCRV1:cMOkc3M=:4pyT",
            OpenVPNCredentialsOTPMethod.encode.encodedPassword("päss", "✓")
        )
        assertEquals(
            "SCRV1::",
            OpenVPNCredentialsOTPMethod.encode.encodedPassword("", "")
        )
    }

    @Test
    fun encodedPassword_doesNotWrapLongCredentials() {
        val encoded = OpenVPNCredentialsOTPMethod.encode.encodedPassword(
            password = "abc".repeat(40),
            otp = "123".repeat(40)
        )

        assertEquals("SCRV1:${"YWJj".repeat(40)}:${"MTIz".repeat(40)}", encoded)
    }

    @Test
    fun withInteractiveLogin_serializesTaggedModuleValue() {
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

        val updated = profile.withInteractiveLogin(
            username = "username",
            password = ""
        )
        val json = tunnelJson.encodeToString(updated)

        assertTrue(json.contains("\"type\":\"OpenVPN\""))
        assertTrue(json.contains("\"value\":{\"id\":\"$MODULE_ID\""))
        assertFalse(json.contains("\"type\":\"OpenVPN\",\"id\":\"$MODULE_ID\""))
    }

    @Test
    fun withInteractiveLogin_updatesOnlyFirstActiveInteractiveModule() {
        val first = OpenVPNModule(id = MODULE_ID, requiresInteractiveCredentials = true)
        val inactive = first.copy(id = "inactive")
        val second = first.copy(id = "second")
        val original = openVPNProfile(first).copy(
            modules = listOf(TaggedModuleOpenVPN(inactive), TaggedModuleOpenVPN(first), TaggedModuleOpenVPN(second)),
            activeModulesIds = setOf(first.id, second.id)
        )
        val updated = original.withInteractiveLogin("user", "secret")
        assertEquals(original.modules[0], updated.modules[0])
        assertEquals(original.modules[2], updated.modules[2])
        assertEquals(original.modules[1].withInteractiveLogin("user", "secret"), updated.modules[1])
        assertEquals("secret", (updated.modules[1] as TaggedModuleOpenVPN).value.credentials?.password)
        assertEquals(null, (original.modules[1] as TaggedModuleOpenVPN).value.credentials)
        assertEquals(original.activeModulesIds, updated.activeModulesIds)
    }

    @Test
    fun withInteractiveLogin_leavesUnsupportedAndNoninteractiveModulesUnchanged() {
        val unsupported: TaggedModule = TaggedModuleIP(IPModule(id = "ip"))
        val noninteractive: TaggedModule = TaggedModuleOpenVPN(OpenVPNModule(id = MODULE_ID))
        assertEquals(unsupported, unsupported.withInteractiveLogin("user", "secret"))
        assertEquals(noninteractive, noninteractive.withInteractiveLogin("user", "secret"))
        val profile = openVPNProfile(OpenVPNModule(id = MODULE_ID))
        assertEquals(profile, profile.withInteractiveLogin("user", "secret"))
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
