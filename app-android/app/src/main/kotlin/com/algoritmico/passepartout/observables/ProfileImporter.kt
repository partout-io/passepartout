// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import com.algoritmico.passepartout.injection.throwIfCancellation
import com.algoritmico.passepartout.managers.ProfileManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.nio.ByteBuffer
import java.nio.charset.CharacterCodingException
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets

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
            val profileName = displayName(uri) ?: DEFAULT_PROFILE_NAME
            val profileText = when (val result = readProfileText(uri)) {
                ProfileTextReadResult.Binary -> {
                    reportFailure("$profileName appears to be a binary file.")
                    return@launch
                }
                ProfileTextReadResult.Failure -> {
                    reportFailure("Unable to read $profileName.")
                    return@launch
                }
                is ProfileTextReadResult.Text -> result.value
            }
            runCatching {
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

    private suspend fun readProfileText(uri: Uri): ProfileTextReadResult = withContext(Dispatchers.IO) {
        runCatching {
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
            if (bytes == null) {
                ProfileTextReadResult.Failure
            } else {
                bytes.decodeProfileTextOrNull()
                    ?.let(ProfileTextReadResult::Text)
                    ?: ProfileTextReadResult.Binary
            }
        }.getOrElse {
            it.throwIfCancellation()
            Log.e(logTag, "Unable to read profile file: $uri", it)
            ProfileTextReadResult.Failure
        }
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

    private fun reportFailure(message: String, cause: Throwable? = null) {
        Log.e(logTag, message, cause)
        errorHandler.report(ProfileImportException(message, cause))
    }

    private sealed class ProfileTextReadResult {
        data class Text(val value: String) : ProfileTextReadResult()
        data object Binary : ProfileTextReadResult()
        data object Failure : ProfileTextReadResult()
    }

    private class ProfileImportException(
        message: String,
        cause: Throwable? = null
    ) : Exception(message, cause)

    companion object {
        val MIME_TYPES = arrayOf(
            "application/x-openvpn-profile",
            "application/x-wireguard-profile",
            "application/octet-stream",
            "text/*",
            "*/*"
        )

        private const val DEFAULT_PROFILE_NAME = "Imported profile"
    }
}

private fun ByteArray.decodeProfileTextOrNull(): String? {
    if (hasBinaryControlBytes()) {
        return null
    }
    val decoder = StandardCharsets.UTF_8
        .newDecoder()
        .onMalformedInput(CodingErrorAction.REPORT)
        .onUnmappableCharacter(CodingErrorAction.REPORT)
    return runCatching {
        decoder.decode(ByteBuffer.wrap(this)).toString()
    }.getOrElse {
        if (it is CharacterCodingException) {
            null
        } else {
            throw it
        }
    }
}

private fun ByteArray.hasBinaryControlBytes(): Boolean {
    if (isEmpty()) {
        return false
    }
    var controlCount = 0
    for (byte in this) {
        val value = byte.toInt() and 0xFF
        if (value == 0) {
            return true
        }
        if (value < ASCII_SPACE && value !in TEXT_CONTROL_BYTES) {
            controlCount += 1
        }
    }
    return controlCount > 0 && controlCount * 100 > size
}

private val TEXT_CONTROL_BYTES = setOf(
    '\t'.code,
    '\n'.code,
    '\r'.code,
    '\u000C'.code
)

private const val ASCII_SPACE = 0x20
