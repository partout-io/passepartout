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
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.util.zip.ZipInputStream

sealed interface ProfileImporterInput {
    class Contents(
        val data: String,
        val filename: String,
        val isFromArchive: Boolean = false
    ) : ProfileImporterInput

    class File(val uri: Uri) : ProfileImporterInput
}

suspend fun ProfileImporterInput.decodedPairs(
    contentResolver: ContentResolver,
    fallbackProfileName: String,
    logTag: String
): List<ProfileImporterInput.Contents> = withContext(Dispatchers.IO) {
    when (this@decodedPairs) {
        is ProfileImporterInput.Contents -> {
            val text = data.toByteArray(Charsets.UTF_8).decodeAsTextOrNull()
                ?: throw ProfileImporterException.Binary
            listOf(ProfileImporterInput.Contents(text, filename, isFromArchive))
        }
        is ProfileImporterInput.File -> {
            val name = contentResolver.displayName(uri, logTag)
            val mimeType = contentResolver.safeMimeType(uri, logTag)
            if (isZipInput(name, mimeType, uri.lastPathSegment)) {
                val stream = contentResolver.openInputStream(uri)
                    ?: throw ProfileImporterException.Null
                return@withContext stream.use { expandZipEntries(it, logTag) }
            }
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
                ?: throw ProfileImporterException.Null
            val text = bytes.decodeAsTextOrNull() ?: throw ProfileImporterException.Binary
            listOf(ProfileImporterInput.Contents(text, name ?: fallbackProfileName))
        }
    }
}

internal fun isZipInput(
    displayName: String?,
    mimeType: String?,
    lastPathSegment: String? = null
): Boolean {
    if (displayName?.endsWith(".zip", ignoreCase = true) == true) {
        return true
    }
    if (lastPathSegment?.endsWith(".zip", ignoreCase = true) == true) {
        return true
    }
    val normalizedMimeType = mimeType?.substringBefore(';')?.trim()?.lowercase()
    return normalizedMimeType in ZIP_MIME_TYPES
}

internal fun expandZipEntries(
    inputStream: InputStream,
    logTag: String
): List<ProfileImporterInput.Contents> {
    val inputs = mutableListOf<ProfileImporterInput.Contents>()
    runCatchingNonFatal {
        ZipInputStream(inputStream).use { zip ->
            while (true) {
                val entry = zip.nextEntry ?: break
                try {
                    val rawName = entry.name
                    if (entry.isDirectory || rawName.endsWith("/") || rawName.endsWith("\\")) {
                        continue
                    }
                    val segments = rawName.split('/', '\\').filter { it.isNotEmpty() }
                    if (segments.isEmpty() || segments.any { it == MACOSX_SEGMENT }) {
                        continue
                    }
                    val filename = segments.last()
                    if (filename.startsWith(".")) {
                        continue
                    }
                    val extension = filename.substringAfterLast('.', missingDelimiterValue = "").lowercase()
                    if (extension !in ZIP_ENTRY_EXTENSIONS) {
                        continue
                    }
                    if (entry.size > MAX_ZIP_ENTRY_SIZE) {
                        logSkippedEntry(logTag, "Skipping oversized archive entry", rawName)
                        continue
                    }
                    val bytes = zip.readEntryBounded(MAX_ZIP_ENTRY_SIZE)
                    if (bytes == null) {
                        logSkippedEntry(logTag, "Skipping oversized archive entry", rawName)
                        continue
                    }
                    val text = bytes.decodeAsTextOrNull()
                    if (text == null) {
                        logSkippedEntry(logTag, "Skipping unreadable archive entry", rawName)
                        continue
                    }
                    inputs += ProfileImporterInput.Contents(
                        data = text,
                        filename = filename,
                        isFromArchive = true
                    )
                } finally {
                    zip.closeEntry()
                }
            }
        }
    }.onFailure { error ->
        AppLog.e(logTag, "Unable to open archive", error)
        throw ProfileImporterException.Failure(null)
    }
    if (inputs.isEmpty()) {
        throw ProfileImporterException.Failure(null)
    }
    return inputs
}

private fun ZipInputStream.readEntryBounded(maxBytes: Int): ByteArray? {
    val output = ByteArrayOutputStream()
    val buffer = ByteArray(ZIP_READ_BUFFER_SIZE)
    var total = 0
    while (true) {
        val remaining = maxBytes - total
        val read = read(buffer, 0, minOf(buffer.size, remaining + 1))
        if (read < 0) {
            break
        }
        total += read
        if (total > maxBytes) {
            return null
        }
        output.write(buffer, 0, read)
    }
    return output.toByteArray()
}

private fun logSkippedEntry(logTag: String, reason: String, entryName: String) {
    val message = if (AppLog.logsPrivateData) "$reason: $entryName" else reason
    AppLog.e(logTag, message)
}

private fun ContentResolver.displayName(uri: Uri, logTag: String): String? {
    val queried = runCatchingNonFatal {
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
    if (!queried.isNullOrBlank()) {
        return queried
    }
    if (uri.scheme == ContentResolver.SCHEME_FILE) {
        return uri.lastPathSegment?.takeIf { it.isNotBlank() }
    }
    return null
}

private fun ContentResolver.safeMimeType(uri: Uri, logTag: String): String? {
    return runCatchingNonFatal {
        getType(uri)
    }.getOrElse {
        AppLog.w(logTag, "Unable to resolve profile MIME type: $uri", it)
        null
    }
}

// Matches app-cross ReadConfiguration's and Apple's per-file cap.
private const val MAX_ZIP_ENTRY_SIZE = 1_000_000
private const val ZIP_READ_BUFFER_SIZE = 8192
private const val MACOSX_SEGMENT = "__MACOSX"
private val ZIP_ENTRY_EXTENSIONS = setOf("ovpn", "conf", "json")
private val ZIP_MIME_TYPES = setOf("application/zip", "application/x-zip-compressed")
