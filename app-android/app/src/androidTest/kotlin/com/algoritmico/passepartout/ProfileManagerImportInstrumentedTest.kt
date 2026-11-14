// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.algoritmico.passepartout.business.managers.ProfileManager
import com.algoritmico.passepartout.business.managers.ProfileRepository
import com.algoritmico.passepartout.context.AndroidConstants
import io.partout.PartoutWrapper
import io.partout.models.TaggedProfile
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.withTimeoutOrNull
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ProfileManagerImportInstrumentedTest {
    @Test
    fun importWaitsForInitialProfiles() = checkStartupImport(loadFails = false)

    @Test
    fun importContinuesAfterInitialLoadFailure() = checkStartupImport(loadFails = true)

    private fun checkStartupImport(loadFails: Boolean) = runBlocking {
        withTimeout(5000) {
            val finishLoad = CompletableDeferred<Unit>()
            val saved = mutableListOf<TaggedProfile>()
            val errors = mutableListOf<Throwable>()
            val repository = object : ProfileRepository {
                override suspend fun fetchProfiles(): Collection<TaggedProfile> {
                    finishLoad.await()
                    if (loadFails) error("Initial load failed")
                    return emptyList()
                }

                override suspend fun saveProfile(profile: TaggedProfile) {
                    saved += profile
                }

                override suspend fun removeProfiles(profileIds: Collection<String>) {}
            }
            val manager = ProfileManager(
                "ProfileManagerImportTest", PartoutWrapper(), repository, AndroidConstants.Events()
            )
            val input = InstrumentationRegistry.getInstrumentation().context.assets
                .open("encrypted.ovpn").bufferedReader().use { it.readText() }
            // Import can arrive even before initialization has started.
            val importing = launch(start = CoroutineStart.UNDISPATCHED) {
                manager.importText(input, "Imported", "import-test")
            }
            val loading = launch(start = CoroutineStart.UNDISPATCHED) {
                manager.loadInitialProfiles(errors::add)
            }
            assertNull(withTimeoutOrNull(1000) { importing.join(); true })
            assertFalse(importing.isCompleted)
            assertTrue(saved.isEmpty())
            finishLoad.complete(Unit)
            loading.join()
            importing.join()
            val imported = saved.single()
            assertEquals(imported, manager.profile(imported.id))
            assertEquals(if (loadFails) 1 else 0, errors.size)
        }
    }
}
