// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.util.Base64
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class WireGuardKeyGeneratorTest {
    @Test
    fun generatedPrivateKeysProduceStablePublicKeys() {
        val app = InstrumentationRegistry.getInstrumentation().targetContext.applicationContext as PassepartoutApplication
        val generator = app.appContext.wireGuardKeyGenerator
        val privateKey = requireNotNull(generator.newPrivateKey())
        val publicKey = requireNotNull(generator.publicKey(privateKey))
        assertEquals(32, Base64.decode(privateKey, Base64.DEFAULT).size)
        assertEquals(32, Base64.decode(publicKey, Base64.DEFAULT).size)
        assertEquals(publicKey, generator.publicKey(privateKey))
        assertNotEquals(privateKey, generator.newPrivateKey())
        assertNull(generator.publicKey("invalid"))
    }
}
