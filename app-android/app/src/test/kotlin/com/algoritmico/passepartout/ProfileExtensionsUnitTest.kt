// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.business.models.InteractiveLogin
import com.algoritmico.passepartout.business.strategy.FileProfileRepository
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
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.Rule
import org.junit.rules.TemporaryFolder

class ProfileExtensionsUnitTest {
    @get:Rule
    val temporaryFolder = TemporaryFolder()

    @Test
    fun interactiveLogin_clearsEachPromptAndPreservesPersistedOTPPassword() = runBlocking {
        for (method in OpenVPNCredentialsOTPMethod.entries) {
            val original = openVPNProfile(OpenVPNModule(
                id = MODULE_ID,
                requiresInteractiveCredentials = true,
                credentials = OpenVPNCredentials(username = "user", password = "saved-secret", otpMethod = method)
            ))
            val directory = temporaryFolder.newFolder(method.name)
            val repository = FileProfileRepository("InteractiveLoginTest", directory)
            repository.saveProfile(original)
            val login = InteractiveLogin(repository.fetchProfiles().single())
            assertEquals("", login.password)
            assertEquals("user", login.username)
            login.password = "123456"
            val prepared = login.connectionProfile().interactiveOpenVPNModule()
            val expected = if (method == OpenVPNCredentialsOTPMethod.none) {
                "123456"
            } else {
                "saved-secret"
            }
            assertEquals(expected, prepared?.credentials?.password)
            assertEquals("saved-secret", original.interactiveOpenVPNModule()?.credentials?.password)
            repository.saveProfile(login.connectionProfile())
            // Reopen the actual app repository, as after an app restart.
            val restored = FileProfileRepository("InteractiveLoginTest", directory).fetchProfiles().single()
            assertEquals(login.connectionProfile(), restored)
            val repeated = InteractiveLogin(restored)
            assertEquals("", repeated.password)
            assertEquals(method != OpenVPNCredentialsOTPMethod.none, repeated.needsOTP)
            assertEquals("user", repeated.username)
            repeated.password = "654321"
            repository.saveProfile(repeated.connectionProfile())
            val nextProfile = FileProfileRepository("InteractiveLoginTest", directory).fetchProfiles().single()
            assertEquals("", InteractiveLogin(nextProfile).password)
            val next = nextProfile.interactiveOpenVPNModule()?.credentials
            assertEquals(method, next?.otpMethod)
            assertEquals(if (repeated.needsOTP) "saved-secret" else "654321", next?.password)
            assertEquals(if (repeated.needsOTP) "654321" else null, next?.otp)
            assertEquals(if (repeated.needsOTP) "123456" else null, prepared?.credentials?.otp)
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
        assertEquals("secret", prepared?.credentials?.password)
        assertEquals("123456", prepared?.credentials?.otp)
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
    fun withInteractiveLogin_preservesRawOTPForAuthentication() {
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
            username = "entered-username",
            password = "ignored-password",
            otp = "123456"
        )
        val credentials = updated.interactiveOpenVPNModule()?.credentials

        assertEquals("entered-username", credentials?.username)
        assertEquals("saved-password", credentials?.password)
        assertEquals(OpenVPNCredentialsOTPMethod.append, credentials?.otpMethod)
        assertEquals("123456", credentials?.otp)
    }

    @Test
    fun withInteractiveLogin_preservesRawSCRV1OTPForAuthentication() {
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
            username = "entered-username",
            password = "ignored-password",
            otp = "123456"
        )
        val credentials = updated.interactiveOpenVPNModule()?.credentials

        assertEquals("entered-username", credentials?.username)
        assertEquals("saved-password", credentials?.password)
        assertEquals(OpenVPNCredentialsOTPMethod.encode, credentials?.otpMethod)
        assertEquals("123456", credentials?.otp)
    }

    @Test
    fun withInteractiveLogin_preservesRawUnicodeCredentialsThroughSerialization() {
        val original = openVPNProfile(OpenVPNModule(
            id = MODULE_ID,
            requiresInteractiveCredentials = true,
            credentials = OpenVPNCredentials(username = "user", password = "päss", otpMethod = OpenVPNCredentialsOTPMethod.encode)
        ))
        val prepared = original.withInteractiveLogin("user", "ignored", otp = "✓")
        val restored = tunnelJson.decodeFromString<TaggedProfile>(tunnelJson.encodeToString(prepared))
        val credentials = restored.interactiveOpenVPNModule()?.credentials
        assertEquals("päss", credentials?.password)
        assertEquals("✓", credentials?.otp)
        assertEquals(OpenVPNCredentialsOTPMethod.encode, credentials?.otpMethod)
    }

    @Test
    fun withInteractiveLogin_clearsStaleOTPWithoutAnOTPMethod() {
        val original = openVPNProfile(OpenVPNModule(
            id = MODULE_ID,
            requiresInteractiveCredentials = true,
            credentials = OpenVPNCredentials(username = "user", password = "old", otpMethod = OpenVPNCredentialsOTPMethod.none, otp = "stale")
        ))
        val credentials = original.withInteractiveLogin("user", "new", otp = "ignored").interactiveOpenVPNModule()?.credentials
        assertEquals("new", credentials?.password)
        assertEquals(null, credentials?.otp)
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
