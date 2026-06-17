// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.observables

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import com.algoritmico.passepartout.injection.Files
import com.algoritmico.passepartout.extensions.decodeAsTextOrNull
import com.algoritmico.passepartout.extensions.throwIfCancellation
import com.algoritmico.passepartout.managers.ProfileManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

sealed class ProfileImporterException: Exception() {
    data object Binary: ProfileImporterException()
    data class Failure(val reason: Throwable?): ProfileImporterException()
}

class ProfileImporter(
    private val logTag: String,
    context: Context,
    private val coroutineScope: CoroutineScope,
    private val profileManager: ProfileManager,
    private val errorHandler: ErrorHandler = ErrorHandler,
    private val onImportSuccess: () -> Unit = {}
) {
    private val contentResolver = context.applicationContext.contentResolver

    fun importProfile(uri: Uri) {
        coroutineScope.launch {
            val profileName = displayName(uri) ?: Files.DEFAULT_PROFILE_NAME
            runCatching {
                val profileText = readProfileText(uri)
                profileManager.importText(profileText, profileName)
            }.onSuccess {
                onImportSuccess()
            }.onFailure {
                it.throwIfCancellation()
                Log.e(logTag, "Import failure: $profileName", it)
                reportFailure("Unable to import $profileName.", it)
            }
        }
    }

    private suspend fun readProfileText(uri: Uri): String = withContext(Dispatchers.IO) {
        val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
        if (bytes == null) {
            throw ProfileImporterException.Failure(null)
        }
        val text = bytes.decodeAsTextOrNull()
        if (text == null) {
            throw ProfileImporterException.Binary
        }
        return@withContext text
    }

    private suspend fun displayName(uri: Uri): String? = withContext(Dispatchers.IO) {
        runCatching {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (!cursor.moveToFirst()) {
                        return@use null
                    }
                    val displayNameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (displayNameIndex >= 0) {
                        cursor.getString(displayNameIndex)
                    } else {
                        null
                    }
                }
        }.getOrElse {
            it.throwIfCancellation()
            Log.e(logTag, "Unable to resolve profile file name: $uri", it)
            null
        }
    }

    private fun reportFailure(message: String, cause: Throwable) {
        Log.e(logTag, message, cause)
        errorHandler.report(cause)
    }
}
