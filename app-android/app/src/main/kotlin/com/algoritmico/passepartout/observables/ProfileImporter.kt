// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.net.Uri
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AppLog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
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

    fun importProfile(uri: Uri) {
        cancelImport()
        import { readProfile(uri) }
    }

    fun importProfile(input: ProfileImportInput) {
        cancelImport()
        import { input }
    }

    fun submitPassphrase(passphrase: String) {
        val input = pendingInput ?: return
        if (_state.value.isImporting) return
        import(passphrase) { input }
    }

    fun cancelImport() {
        job?.cancel()
        job = null
        pendingInput = null
        _state.value = State()
    }

    private fun import(
        passphrase: String? = null,
        read: suspend () -> ProfileImportInput
    ) {
        _state.value = State(isImporting = true)
        job = coroutineScope.launch {
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
                    pendingInput = null
                    _state.value = State()
                    reportFailure(error)
                }
                return@launch
            }
            currentCoroutineContext().ensureActive()
            pendingInput = null
            _state.value = State()
            onImportSuccess()
        }
    }

    private fun reportFailure(error: Throwable) {
        reportError(
            if (error is ProfileImporterException) error
            else ProfileImporterException.Failure(error)
        )
    }

    override fun close() {
        cancelImport()
    }

    data class State(
        val isImporting: Boolean = false,
        val passphraseFilename: String? = null
    )
}
