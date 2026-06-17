// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.injection

import android.util.Log
import androidx.compose.ui.platform.UriHandler
import com.algoritmico.passepartout.observables.ErrorHandler
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.encodeToJsonElement
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets

fun UriHandler.safeOpenUri(uri: String, handler: ErrorHandler) {
    runCatching {
        openUri(uri)
    }.onFailure {
        Log.e(Tags.APP, "Unable to open URL ($uri)", it)
        handler.report(it)
    }
}

fun Throwable.throwIfCancellation() {
    if (this is CancellationException) {
        throw this
    }
}

object JSON {
    val _coder = Json {
        ignoreUnknownKeys = true
    }

    inline fun <reified T> encode(value: T): String {
        return _coder.encodeToString(value)
    }

    inline fun <reified T> encodeElement(value: T): JsonElement {
        return _coder.encodeToJsonElement(value)
    }

    inline fun <reified T> decode(json: String): T {
        return _coder.decodeFromString<T>(json)
    }
}

fun ByteArray.decodeAsTextOrNull(): String? {
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
        it.throwIfCancellation()
        when (it) {
            is CharacterCodingException -> null
            else -> throw it
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
