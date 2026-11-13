// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.observables.ProfileImporter
import com.algoritmico.passepartout.observables.ProfileImportInput
import io.partout.abi.PartoutException
import io.partout.models.PartoutErrorCode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray
import org.junit.Assert.*
import org.junit.Test

class ProfileImporterUnitTest {
    @Test
    fun passphraseRetryPreservesInputAndCompletesOnce() {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val phrases = mutableListOf<String?>()
        var successes = 0
        val importer = ProfileImporter(scope, { error("Unexpected read") }, { text, name, phrase ->
            assertEquals("encrypted", text)
            assertEquals("Private.ovpn", name)
            phrases += phrase
            if (phrase != "correct") throw parsingError(
                if (phrase == null) "passphraseRequired" else "unableToDecrypt"
            )
        }, { throw AssertionError(it) }, { successes++ })
        try {
            importer.importProfile(ProfileImportInput("encrypted", "Private.ovpn"))
            assertEquals("Private.ovpn", importer.state.value.passphraseFilename)
            importer.submitPassphrase("wrong")
            assertEquals("Private.ovpn", importer.state.value.passphraseFilename)
            importer.submitPassphrase("correct")
            assertNull(importer.state.value.passphraseFilename)
            assertFalse(importer.state.value.isImporting)
            importer.submitPassphrase("correct")
            assertEquals(listOf(null, "wrong", "correct"), phrases)
            assertEquals(1, successes)
        } finally {
            scope.cancel()
        }
    }

    @Test
    fun cancellationDiscardsPendingInput() {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        var attempts = 0
        val importer = ProfileImporter(scope, { error("Unexpected read") }, { _, _, _ ->
            attempts++
            throw parsingError("passphraseRequired")
        }, { throw AssertionError(it) })
        try {
            importer.importProfile(ProfileImportInput("encrypted", "Private.ovpn"))
            importer.cancelImport()
            importer.submitPassphrase("ignored")
            assertEquals(1, attempts)
            assertEquals(ProfileImporter.State(), importer.state.value)
        } finally {
            scope.cancel()
        }
    }

    @Test
    fun unrelatedParsingFailureIsReportedWithoutPrompt() {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val failures = mutableListOf<Throwable>()
        val importer = ProfileImporter(scope, { error("Unexpected read") }, { _, _, _ ->
            throw parsingError("unsupportedOption")
        }, failures::add)
        try {
            importer.importProfile(ProfileImportInput("invalid", "Invalid.ovpn"))
            assertEquals(1, failures.size)
            assertEquals(ProfileImporter.State(), importer.state.value)
        } finally {
            scope.cancel()
        }
    }

    @Test
    fun supersededImportCannotRestoreOldPrompt() = runBlocking {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val release = CompletableDeferred<Unit>()
        var successes = 0
        val importer = ProfileImporter(scope, { error("Unexpected read") }, { _, name, _ ->
            if (name == "Old.ovpn") {
                withContext(NonCancellable) { release.await() }
                throw parsingError("passphraseRequired")
            }
        }, { throw AssertionError(it) }, { successes++ })
        try {
            importer.importProfile(ProfileImportInput("old", "Old.ovpn"))
            importer.importProfile(ProfileImportInput("new", "New.ovpn"))
            release.complete(Unit)
            assertEquals(ProfileImporter.State(), importer.state.value)
            assertEquals(1, successes)
        } finally {
            scope.cancel()
        }
    }

    private fun parsingError(subCode: String) = PartoutException(
        code = PartoutErrorCode.parsing,
        payload = buildJsonObject {
            put("recognizedType", "OpenVPN")
            put("subCode", subCode)
            putJsonArray("arguments") {}
        }
    )
}
