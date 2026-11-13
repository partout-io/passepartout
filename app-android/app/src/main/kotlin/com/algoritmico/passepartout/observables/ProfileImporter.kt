// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.net.Uri
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AppLog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import io.partout.abi.PartoutException
import com.algoritmico.passepartout.business.extensions.isOpenVPNPassphraseRequired
import java.io.Closeable

sealed class ProfileImporterException: Exception() {
    data object Binary: ProfileImporterException()
    data object Null: ProfileImporterException()
    data class Failure(override val cause: Throwable?): ProfileImporterException() {
        override fun toString(): String =
            if (AppLog.logsPrivateData) "Failure(cause=$cause)" else "Failure"
    }
}

class ProfileImportInput(val text: String, val name: String)

class ProfileImporter(
    private val coroutineScope: CoroutineScope,
    private val readProfile: suspend (Uri) -> ProfileImportInput,
    private val importText: suspend (String, String, String?) -> Unit,
    private val reportError: (Throwable) -> Unit,
    private val onImportSuccess: () -> Unit = {}
) : Closeable {
    private val _state = MutableStateFlow(State())
    val state = _state.asStateFlow()
    private var pendingInput: ProfileImportInput? = null
    private var job: Job? = null
    private val queue = ArrayDeque<suspend () -> ProfileImportInput>()

    fun importProfiles(uris: List<Uri>) {
        start(uris.map { uri -> { readProfile(uri) } })
    }

    fun importProfile(vararg inputs: ProfileImportInput) {
        start(inputs.map { input -> { input } })
    }

    private fun start(readers: List<suspend () -> ProfileImportInput>) {
        close()
        queue.addAll(readers)
        importNext()
    }

    private fun importNext() {
        pendingInput = null
        _state.value = State()
        val read = queue.removeFirstOrNull() ?: return
        import(read = read)
    }

    fun submitPassphrase(passphrase: String) {
        val input = pendingInput ?: return
        if (_state.value.isImporting) return
        import(passphrase) { input }
    }

    fun skipImport() {
        job?.cancel()
        job = null
        importNext()
    }

    private fun import(
        passphrase: String? = null,
        read: suspend () -> ProfileImportInput
    ) {
        _state.value = State(isImporting = true)
        job = coroutineScope.launch(start = CoroutineStart.LAZY) {
            runCatchingNonFatal {
                val input = read()
                currentCoroutineContext().ensureActive()
                pendingInput = input
                importText(input.text, input.name, passphrase)
            }.onFailure { error ->
                currentCoroutineContext().ensureActive()
                if (error is PartoutException && error.isOpenVPNPassphraseRequired) {
                    _state.value = State(passphraseFilename = pendingInput?.name)
                } else {
                    reportFailure(error)
                    importNext()
                }
                return@launch
            }
            currentCoroutineContext().ensureActive()
            onImportSuccess()
            importNext()
        }
        job?.start()
    }

    private fun reportFailure(error: Throwable) {
        reportError(
            if (error is ProfileImporterException) error
            else ProfileImporterException.Failure(error)
        )
    }

    override fun close() {
        job?.cancel()
        job = null
        queue.clear()
        pendingInput = null
        _state.value = State()
    }

    data class State(
        val isImporting: Boolean = false,
        val passphraseFilename: String? = null
    )
}
