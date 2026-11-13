// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import com.algoritmico.passepartout.business.extensions.decodeAsTextOrNull
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AppLog
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class AndroidProfileImportReader(
    private val logTag: String,
    context: Context,
    private val fallbackProfileName: String
) {
    private val contentResolver = context.applicationContext.contentResolver

    suspend fun read(uri: Uri): ProfileImportInput {
        val name = displayName(uri) ?: fallbackProfileName
        return ProfileImportInput(readProfileText(uri), name)
    }

    private suspend fun readProfileText(uri: Uri): String = withContext(Dispatchers.IO) {
        val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
            ?: throw ProfileImporterException.Null
        bytes.decodeAsTextOrNull() ?: throw ProfileImporterException.Binary
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
