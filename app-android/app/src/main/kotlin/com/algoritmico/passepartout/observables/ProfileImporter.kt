// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import com.algoritmico.passepartout.business.extensions.isOpenVPNPassphraseRequired
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.models.ProfileImporterInput
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.context.defaultAndroidConstants
import io.partout.abi.PartoutException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.Closeable

sealed class ProfileImporterException: Exception() {
    data object Binary: ProfileImporterException()
    data object Null: ProfileImporterException()
    data class Partial(val imported: Int, val total: Int): ProfileImporterException()
    data class Failure(override val cause: Throwable?): ProfileImporterException() {
        override fun toString(): String =
            if (AppLog.logsPrivateData) "Failure(cause=$cause)" else "Failure"
    }
}

class ProfileImporter(
    private val coroutineScope: CoroutineScope,
    private val readProfiles: suspend (ProfileImporterInput) -> List<ProfileImporterInput.Contents>,
    private val importText: suspend (String, String, String?) -> Unit,
    private val reportError: (Throwable) -> Unit,
    private val onImportSuccess: () -> Unit = {},
    private val logTag: String = defaultAndroidConstants.tags.app
) : Closeable {
    private val _state = MutableStateFlow(State())
    val state = _state.asStateFlow()
    private var pendingInput: ProfileImporterInput.Contents? = null
    private var job: Job? = null
    private val queue = ArrayDeque<QueueItem>()
    private var batchImported = 0
    private var batchFailed = 0

    fun importProfiles(inputs: List<ProfileImporterInput>) {
        start(inputs.map { QueueItem.Unread(it) })
    }

    fun importProfile(vararg inputs: ProfileImporterInput.Contents) {
        importProfiles(inputs.toList())
    }

    private fun start(items: List<QueueItem>) {
        close()
        queue.addAll(items)
        importNext()
    }

    private fun importNext() {
        pendingInput = null
        _state.value = State()
        val next = queue.removeFirstOrNull()
        if (next == null) {
            finishBatch()
            return
        }
        import(item = next)
    }

    private fun finishBatch() {
        val imported = batchImported
        val failed = batchFailed
        batchImported = 0
        batchFailed = 0
        if (failed > 0) {
            reportError(
                ProfileImporterException.Partial(
                    imported = imported,
                    total = imported + failed
                )
            )
        }
    }

    fun submitPassphrase(passphrase: String) {
        val input = pendingInput ?: return
        if (_state.value.isImporting) return
        import(passphrase = passphrase, item = QueueItem.Ready(input))
    }

    fun skipImport() {
        job?.cancel()
        job = null
        importNext()
    }

    private fun import(
        passphrase: String? = null,
        item: QueueItem
    ) {
        _state.value = State(isImporting = true)
        job = coroutineScope.launch(start = CoroutineStart.LAZY) {
            val input = when (item) {
                is QueueItem.Ready -> item.input
                is QueueItem.Unread -> {
                    val expanded = runCatchingNonFatal {
                        readProfiles(item.input)
                    }.getOrElse { error ->
                        currentCoroutineContext().ensureActive()
                        reportFailure(error)
                        importNext()
                        return@launch
                    }
                    currentCoroutineContext().ensureActive()
                    if (expanded.isEmpty()) {
                        importNext()
                        return@launch
                    }
                    for (index in expanded.lastIndex downTo 1) {
                        queue.addFirst(QueueItem.Ready(expanded[index]))
                    }
                    expanded.first()
                }
            }

            pendingInput = input
            runCatchingNonFatal {
                importText(input.data, input.filename, passphrase)
            }.onFailure { error ->
                currentCoroutineContext().ensureActive()
                if (error is PartoutException && error.isOpenVPNPassphraseRequired) {
                    _state.value = State(passphraseFilename = input.filename)
                } else if (input.isFromArchive) {
                    AppLog.e(logTag, "Unable to import archive entry", error)
                    batchFailed += 1
                    importNext()
                } else {
                    reportFailure(error)
                    importNext()
                }
                return@launch
            }

            currentCoroutineContext().ensureActive()
            batchImported += 1
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
        batchImported = 0
        batchFailed = 0
        _state.value = State()
    }

    data class State(
        val isImporting: Boolean = false,
        val passphraseFilename: String? = null
    )

    private sealed interface QueueItem {
        data class Unread(val input: ProfileImporterInput) : QueueItem
        data class Ready(val input: ProfileImporterInput.Contents) : QueueItem
    }
}
