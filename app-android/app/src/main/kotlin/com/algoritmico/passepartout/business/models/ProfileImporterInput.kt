// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.models

import android.content.ContentResolver
import android.net.Uri
import android.provider.OpenableColumns
import com.algoritmico.passepartout.business.extensions.decodeAsTextOrNull
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.observables.ProfileImporterException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

sealed interface ProfileImporterInput {
    class Contents(val data: String, val filename: String) : ProfileImporterInput
    class File(val uri: Uri) : ProfileImporterInput
}

suspend fun ProfileImporterInput.decodedPair(
    contentResolver: ContentResolver,
    fallbackProfileName: String,
    logTag: String
): ProfileImporterInput.Contents = withContext(Dispatchers.IO) {
    when (this@decodedPair) {
        is ProfileImporterInput.Contents -> {
            val text = data.toByteArray(Charsets.UTF_8).decodeAsTextOrNull()
                ?: throw ProfileImporterException.Binary
            ProfileImporterInput.Contents(text, filename)
        }
        is ProfileImporterInput.File -> {
            val name = contentResolver.displayName(uri, logTag) ?: fallbackProfileName
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
                ?: throw ProfileImporterException.Null
            val text = bytes.decodeAsTextOrNull() ?: throw ProfileImporterException.Binary
            ProfileImporterInput.Contents(text, name)
        }
    }
}

private fun ContentResolver.displayName(uri: Uri, logTag: String): String? {
    return runCatchingNonFatal {
        query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
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
