// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import com.algoritmico.passepartout.business.extensions.decodeAsTextOrNull
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.managers.ProfileManager
import com.algoritmico.passepartout.context.AppLog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

sealed class ProfileImporterException: Exception() {
    data object Binary: ProfileImporterException()
    data object Null: ProfileImporterException()
    data class Failure(override val cause: Throwable?): ProfileImporterException()
}

class ProfileImporter(
    private val logTag: String,
    context: Context,
    private val coroutineScope: CoroutineScope,
    private val profileManager: ProfileManager,
    private val fallbackProfileName: String,
    private val errorHandler: ErrorHandler,
    private val onImportSuccess: () -> Unit = {}
) {
    private val contentResolver = context.applicationContext.contentResolver

    fun importProfile(uri: Uri) {
        coroutineScope.launch {
            val profileName = displayName(uri) ?: fallbackProfileName
            runCatchingNonFatal {
                val profileText = readProfileText(uri)
                profileManager.importText(profileText, profileName)
            }.onSuccess {
                AppLog.i(logTag, "Imported profile ($profileName)")
                onImportSuccess()
            }.onFailure {
                AppLog.e(logTag, "Unable to import profile ($profileName)", it)
                if (it is ProfileImporterException) {
                    errorHandler.report(it)
                } else {
                    errorHandler.report(ProfileImporterException.Failure(it))
                }
            }
        }
    }

    private suspend fun readProfileText(uri: Uri): String = withContext(Dispatchers.IO) {
        val bytes = runCatchingNonFatal {
            contentResolver.openInputStream(uri)?.use { it.readBytes() }
        }.getOrElse {
            throw it
        }
        if (bytes == null) {
            throw ProfileImporterException.Null
        }
        val text = bytes.decodeAsTextOrNull()
        if (text == null) {
            throw ProfileImporterException.Binary
        }
        return@withContext text
    }

    private suspend fun displayName(uri: Uri): String? = withContext(Dispatchers.IO) {
        runCatchingNonFatal {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (!cursor.moveToFirst()) {
                        return@use null
                    }
                    val displayNameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (displayNameIndex < 0) {
                        return@use null
                    }
                    cursor.getString(displayNameIndex)
                }
        }.getOrElse {
            AppLog.w(logTag, "Unable to resolve profile file name: $uri", it)
            null
        }
    }
}
