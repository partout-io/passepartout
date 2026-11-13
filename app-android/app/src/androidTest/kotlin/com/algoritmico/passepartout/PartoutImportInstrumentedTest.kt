// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import io.partout.PartoutWrapper
import io.partout.abi.PartoutException
import io.partout.models.ModuleType
import io.partout.models.ModuleImportContextOpenVPN
import io.partout.extensions.moduleType
import com.algoritmico.passepartout.business.extensions.parseErrorInfo
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class PartoutImportInstrumentedTest {
    private val library = PartoutWrapper()

    @Test
    fun encryptedOpenVPNImportRetriesAndExports() = runBlocking {
        val input = InstrumentationRegistry.getInstrumentation().context.assets
            .open("encrypted.ovpn").bufferedReader().use { it.readText() }
        try {
            library.importProfile(input, "Encrypted")
            fail("Expected passphrase request")
        } catch (error: PartoutException) {
            assertEquals("passphraseRequired", error.parseErrorInfo?.subCode)
        }
        try {
            library.importProfile(input, "Encrypted", "wrong")
            fail("Expected decryption failure")
        } catch (error: PartoutException) {
            assertEquals("unableToDecrypt", error.parseErrorInfo?.subCode)
        }
        val profile = library.importProfile(input, "Encrypted", "import-test")
        assertEquals("Encrypted", profile.name)
        val module = profile.modules.single()
        assertEquals(ModuleType.OpenVPN, module.moduleType)
        val exported = library.exportModule(module)
        assertNotNull(exported)
        assertFalse(exported!!.contains("ENCRYPTED"))
        assertEquals(ModuleType.OpenVPN, library.importModule(exported).moduleType)
        assertEquals(
            ModuleType.OpenVPN,
            library.importModule(input, ModuleImportContextOpenVPN("import-test")).moduleType
        )
    }

    @Test
    fun nativeUtilityBindings() {
        assertTrue(library.partoutVersion().isNotEmpty())
        val key = library.partoutWireGuardGenKey()
        assertNotNull(key)
        assertEquals(44, key!!.length)
        assertEquals(44, library.partoutWireGuardPubKey(key)!!.length)
        assertNull(library.partoutWireGuardPubKey("invalid"))
        assertNull(library.partoutExportModule("invalid"))
    }
}
