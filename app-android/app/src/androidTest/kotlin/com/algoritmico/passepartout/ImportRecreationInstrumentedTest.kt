// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.algoritmico.passepartout.observables.AppContext
import com.algoritmico.passepartout.observables.ProfileImportInput
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.junit.Assert.assertSame
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ImportRecreationInstrumentedTest {
    @Test
    fun recreationPreservesPassphrasePromptAndRemainingFiles() = runBlocking<Unit> {
        val text = InstrumentationRegistry.getInstrumentation().context.assets
            .open("encrypted.ovpn").bufferedReader().use { it.readText() }
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            lateinit var context: AppContext
            scenario.onActivity {
                context = (it.application as PassepartoutApplication).appContext
                context.profileImporter.importProfile(
                    ProfileImportInput(text, "first.ovpn"),
                    ProfileImportInput(text, "second.ovpn")
                )
            }
            withTimeout(5000) {
                context.profileImporter.state.first { it.passphraseFilename == "first.ovpn" }
            }
            scenario.recreate()
            scenario.onActivity {
                assertSame(context, (it.application as PassepartoutApplication).appContext)
                context.profileImporter.skipImport()
            }
            withTimeout(5000) {
                context.profileImporter.state.first { it.passphraseFilename == "second.ovpn" }
            }
            scenario.onActivity { context.profileImporter.close() }
        }
    }
}
