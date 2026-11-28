// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.business.models.ProfileImporterInput
import com.algoritmico.passepartout.models.AppErrorCode
import com.algoritmico.passepartout.observables.ProfileImporter
import com.algoritmico.passepartout.observables.ProfileImporterException
import com.algoritmico.passepartout.observables.asAppError
import io.partout.abi.PartoutException
import io.partout.models.PartoutErrorCode
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
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
        val importer = ProfileImporter(scope, { listOf(it as ProfileImporterInput.Contents) }, { text, name, phrase ->
            assertEquals("encrypted", text)
            assertEquals("Private.ovpn", name)
            phrases += phrase
            if (phrase != "correct") throw parsingError(
                if (phrase == null) "passphraseRequired" else "unableToDecrypt"
            )
        }, { throw AssertionError(it) }, { successes++ })
        try {
            importer.importProfile(ProfileImporterInput.Contents("encrypted", "Private.ovpn"))
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
        val importer = ProfileImporter(scope, { listOf(it as ProfileImporterInput.Contents) }, { _, _, _ ->
            attempts++
            throw parsingError("passphraseRequired")
        }, { throw AssertionError(it) })
        try {
            importer.importProfile(ProfileImporterInput.Contents("encrypted", "Private.ovpn"))
            importer.skipImport()
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
        val importer = ProfileImporter(scope, { listOf(it as ProfileImporterInput.Contents) }, { _, _, _ ->
            throw parsingError("unsupportedOption")
        }, failures::add)
        try {
            importer.importProfile(ProfileImporterInput.Contents("invalid", "Invalid.ovpn"))
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
        val importer = ProfileImporter(scope, { listOf(it as ProfileImporterInput.Contents) }, { _, name, _ ->
            if (name == "Old.ovpn") {
                withContext(NonCancellable) { release.await() }
                throw parsingError("passphraseRequired")
            }
        }, { throw AssertionError(it) }, { successes++ })
        try {
            importer.importProfile(ProfileImporterInput.Contents("old", "Old.ovpn"))
            importer.importProfile(ProfileImporterInput.Contents("new", "New.ovpn"))
            release.complete(Unit)
            assertEquals(ProfileImporter.State(), importer.state.value)
            assertEquals(1, successes)
        } finally {
            scope.cancel()
        }
    }

    @Test
    fun batchContinuesAfterPassphraseCancellationAndFailure() {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val imported = mutableListOf<String>()
        val failures = mutableListOf<Throwable>()
        val importer = ProfileImporter(scope, { listOf(it as ProfileImporterInput.Contents) }, { _, name, phrase ->
            when (name) {
                "skip", "decrypt" -> if (phrase != "correct") throw parsingError("passphraseRequired")
                "invalid" -> throw parsingError("unsupportedOption")
            }
            imported += name
        }, failures::add)
        try {
            importer.importProfile(*listOf("first", "skip", "invalid", "decrypt", "last")
                .map { ProfileImporterInput.Contents("profile", it) }.toTypedArray())
            assertEquals(listOf("first"), imported)
            assertEquals("skip", importer.state.value.passphraseFilename)
            importer.skipImport()
            assertEquals(1, failures.size)
            assertEquals("decrypt", importer.state.value.passphraseFilename)
            importer.submitPassphrase("correct")
            assertEquals(listOf("first", "decrypt", "last"), imported)
            assertEquals(ProfileImporter.State(), importer.state.value)
        } finally {
            scope.cancel()
        }
    }

    @Test
    fun closeDiscardsBatchWithoutStartingNextImport() {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val attempts = mutableListOf<String>()
        val importer = ProfileImporter(scope, { listOf(it as ProfileImporterInput.Contents) }, { _, name, _ ->
            attempts += name
            throw parsingError("passphraseRequired")
        }, { throw AssertionError(it) })
        try {
            importer.importProfile(
                ProfileImporterInput.Contents("encrypted", "first"),
                ProfileImporterInput.Contents("encrypted", "second")
            )
            importer.close()
            importer.submitPassphrase("ignored")
            importer.skipImport()
            assertEquals(listOf("first"), attempts)
            assertEquals(ProfileImporter.State(), importer.state.value)
        } finally {
            scope.cancel()
        }
    }

    @Test
    fun archivePartialFailureImportsValidEntriesAndReportsSinglePartialNotice() {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val imported = mutableListOf<String>()
        val failures = mutableListOf<Throwable>()
        val importer = ProfileImporter(
            scope,
            {
                listOf(
                    ProfileImporterInput.Contents("ok1", "good1.ovpn", isFromArchive = true),
                    ProfileImporterInput.Contents("bad", "bad.ovpn", isFromArchive = true),
                    ProfileImporterInput.Contents("ok2", "good2.conf", isFromArchive = true)
                )
            },
            { _, name, _ ->
                if (name == "bad.ovpn") throw parsingError("unsupportedOption")
                imported += name
            },
            failures::add
        )
        try {
            importer.importProfile(ProfileImporterInput.Contents("placeholder", "bundle.zip"))
            assertEquals(listOf("good1.ovpn", "good2.conf"), imported)
            val partial = failures.single() as ProfileImporterException.Partial
            assertEquals(2, partial.imported)
            assertEquals(3, partial.total)
            assertEquals(AppErrorCode.importError, partial.asAppError.code)
        } finally {
            scope.cancel()
        }
    }

    @Test
    fun archiveAllFailingEntriesReportZeroOfTotalPartialNotice() {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val failures = mutableListOf<Throwable>()
        val importer = ProfileImporter(
            scope,
            {
                listOf(
                    ProfileImporterInput.Contents("bad1", "bad1.ovpn", isFromArchive = true),
                    ProfileImporterInput.Contents("bad2", "bad2.conf", isFromArchive = true)
                )
            },
            { _, _, _ -> throw parsingError("unsupportedOption") },
            failures::add
        )
        try {
            importer.importProfile(ProfileImporterInput.Contents("placeholder", "bad.zip"))
            val partial = failures.single() as ProfileImporterException.Partial
            assertEquals(0, partial.imported)
            assertEquals(2, partial.total)
        } finally {
            scope.cancel()
        }
    }

    @Test
    fun archiveEncryptedEntryPromptsWithoutPrecountingAndUpdatesPartialNotice() {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val imported = mutableListOf<String>()
        val failures = mutableListOf<Throwable>()
        val importer = ProfileImporter(
            scope,
            {
                listOf(
                    ProfileImporterInput.Contents("ok", "good.ovpn", isFromArchive = true),
                    ProfileImporterInput.Contents("enc", "secret.ovpn", isFromArchive = true),
                    ProfileImporterInput.Contents("bad", "bad.ovpn", isFromArchive = true)
                )
            },
            { _, name, phrase ->
                when (name) {
                    "secret.ovpn" -> if (phrase != "correct") {
                        throw parsingError(if (phrase == null) "passphraseRequired" else "unableToDecrypt")
                    }
                    "bad.ovpn" -> throw parsingError("unsupportedOption")
                }
                imported += name
            },
            failures::add
        )
        try {
            importer.importProfile(ProfileImporterInput.Contents("placeholder", "bundle.zip"))
            assertEquals(listOf("good.ovpn"), imported)
            assertEquals("secret.ovpn", importer.state.value.passphraseFilename)
            assertTrue(failures.isEmpty())

            importer.submitPassphrase("wrong")
            assertEquals("secret.ovpn", importer.state.value.passphraseFilename)
            assertTrue(failures.isEmpty())

            importer.submitPassphrase("correct")
            assertEquals(listOf("good.ovpn", "secret.ovpn"), imported)
            assertEquals(ProfileImporter.State(), importer.state.value)
            val partial = failures.single() as ProfileImporterException.Partial
            assertEquals(2, partial.imported)
            assertEquals(3, partial.total)
        } finally {
            scope.cancel()
        }
    }

    @Test
    fun archiveSkippedEncryptedEntryIsNotCountedInPartialNotice() {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val imported = mutableListOf<String>()
        val failures = mutableListOf<Throwable>()
        val importer = ProfileImporter(
            scope,
            {
                listOf(
                    ProfileImporterInput.Contents("ok", "good.ovpn", isFromArchive = true),
                    ProfileImporterInput.Contents("enc", "secret.ovpn", isFromArchive = true),
                    ProfileImporterInput.Contents("bad", "bad.ovpn", isFromArchive = true)
                )
            },
            { _, name, phrase ->
                when (name) {
                    "secret.ovpn" -> if (phrase != "correct") throw parsingError("passphraseRequired")
                    "bad.ovpn" -> throw parsingError("unsupportedOption")
                }
                imported += name
            },
            failures::add
        )
        try {
            importer.importProfile(ProfileImporterInput.Contents("placeholder", "bundle.zip"))
            assertEquals("secret.ovpn", importer.state.value.passphraseFilename)
            importer.skipImport()
            assertEquals(listOf("good.ovpn"), imported)
            val partial = failures.single() as ProfileImporterException.Partial
            assertEquals(1, partial.imported)
            assertEquals(2, partial.total)
        } finally {
            scope.cancel()
        }
    }

    @Test
    fun explicitFileFailuresPreserveBinaryAndPerFileReporting() {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val failures = mutableListOf<Throwable>()
        val importer = ProfileImporter(
            scope,
            { input ->
                val contents = input as ProfileImporterInput.Contents
                if (contents.filename == "binary.bin") {
                    throw ProfileImporterException.Binary
                }
                listOf(contents)
            },
            { _, _, _ -> throw parsingError("unsupportedOption") },
            failures::add
        )
        try {
            importer.importProfile(
                ProfileImporterInput.Contents("bin", "binary.bin"),
                ProfileImporterInput.Contents("bad", "bad.ovpn")
            )
            assertEquals(2, failures.size)
            assertSame(ProfileImporterException.Binary, failures[0])
            assertTrue(failures[1] is ProfileImporterException.Failure)
            assertFalse(failures.any { it is ProfileImporterException.Partial })
        } finally {
            scope.cancel()
        }
    }

    @Test
    fun closeMidArchiveBatchDiscardsPartialCounts() {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val failures = mutableListOf<Throwable>()
        val importer = ProfileImporter(
            scope,
            {
                listOf(
                    ProfileImporterInput.Contents("bad", "bad.ovpn", isFromArchive = true),
                    ProfileImporterInput.Contents("enc", "secret.ovpn", isFromArchive = true)
                )
            },
            { _, name, _ ->
                if (name == "bad.ovpn") throw parsingError("unsupportedOption")
                throw parsingError("passphraseRequired")
            },
            failures::add
        )
        try {
            importer.importProfile(ProfileImporterInput.Contents("placeholder", "bundle.zip"))
            assertEquals("secret.ovpn", importer.state.value.passphraseFilename)
            importer.close()
            assertTrue(failures.isEmpty())
            assertEquals(ProfileImporter.State(), importer.state.value)
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
