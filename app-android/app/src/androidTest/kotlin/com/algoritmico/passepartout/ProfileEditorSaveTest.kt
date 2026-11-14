// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import androidx.test.ext.junit.runners.AndroidJUnit4
import com.algoritmico.passepartout.business.managers.ProfileManager
import com.algoritmico.passepartout.business.managers.ProfileRepository
import com.algoritmico.passepartout.context.AndroidConstants
import com.algoritmico.passepartout.observables.ErrorHandler
import com.algoritmico.passepartout.observables.ProfileObservable
import io.partout.PartoutWrapper
import io.partout.models.TaggedProfile
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ProfileEditorSaveTest {
    private val original = TaggedProfile("profile", "Original", emptyList(), emptySet())

    @Test
    fun failedSaveRetainsDraftAndRetryPersistsOnce() = runBlocking {
        withTimeout(5000) {
            val repository = Repository(original)
            val profiles = observable(repository, this)
            try {
                profiles.state.first { it.isReady }
                profiles.beginEditing(original.id)
                val editor = requireNotNull(profiles.editor.value)
                profiles.saveEditor()
                assertFalse(profiles.editorSaving.value)
                editor.rename(" ")
                profiles.saveEditor()
                assertFalse(profiles.editorSaving.value)
                assertEquals(0, repository.attempts)

                editor.rename("Renamed")
                profiles.saveEditor()
                profiles.saveEditor()
                profiles.endEditing()
                repository.started.await()
                assertSame(editor, profiles.editor.value)
                assertEquals(1, repository.attempts)
                repository.result.completeExceptionally(IllegalStateException("Save failed"))
                profiles.editorSaving.first { !it }
                assertNotNull(profiles.editorError.value)
                assertSame(editor, profiles.editor.value)
                assertEquals(original, repository.saved)
                assertEquals(original, profiles.profile(original.id))

                profiles.clearEditorError()
                assertNull(profiles.editorError.value)
                repository.result = CompletableDeferred(Unit)
                profiles.saveEditor()
                profiles.editorSaving.first { !it }
                assertNull(profiles.editor.value)
                assertEquals(editor.state.value, repository.saved)
                assertEquals(repository.saved, profiles.profile(original.id))
                assertEquals(2, repository.attempts)
            } finally {
                profiles.close()
            }
        }
    }

    @Test
    fun closingDuringSaveReleasesSessionWithoutPersisting() = runBlocking {
        withTimeout(5000) {
            val repository = Repository(original)
            val profiles = observable(repository, this)
            try {
                profiles.state.first { it.isReady }
                profiles.beginEditing(original.id)
                requireNotNull(profiles.editor.value).rename("Renamed")
                profiles.saveEditor()
                repository.started.await()
                profiles.close()
                assertNull(profiles.editor.value)
                assertNull(profiles.editorError.value)
                assertFalse(profiles.editorSaving.value)
                assertEquals(original, repository.saved)
            } finally {
                profiles.close()
            }
        }
    }

    private fun observable(repository: Repository, scope: CoroutineScope) = ProfileObservable(
        ProfileManager("ProfileEditorSaveTest", PartoutWrapper(), repository, AndroidConstants.Events()),
        scope,
        ErrorHandler("ProfileEditorSaveTest"),
        searchDebounceMillis = 0
    )

    private class Repository(initial: TaggedProfile) : ProfileRepository {
        var saved = initial
        var attempts = 0
        val started = CompletableDeferred<Unit>()
        var result = CompletableDeferred<Unit>()

        override suspend fun fetchProfiles() = listOf(saved)

        override suspend fun saveProfile(profile: TaggedProfile) {
            attempts += 1
            started.complete(Unit)
            result.await()
            saved = profile
        }

        override suspend fun removeProfiles(profileIds: Collection<String>) = Unit
    }
}
