// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.extensions

import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.encodeToJsonElement
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets

//region Exceptions
data class GenericException(
    override val message: String?,
    override val cause: Throwable? = null
): Exception() {
    override fun getLocalizedMessage(): String? {
        return cause?.localizedMessage ?: message
    }
}

class NonFatalResult<T> @PublishedApi internal constructor(
    @PublishedApi internal val result: Result<T>
) {
    inline fun onSuccess(action: (value: T) -> Unit): NonFatalResult<T> {
        result.onSuccess(action)
        return this
    }

    inline fun onFailure(action: (exception: Throwable) -> Unit): NonFatalResult<T> {
        val error = result.exceptionOrNull() ?: return this
        error.throwIfFatal()
        action(error)
        return this
    }

    inline fun getOrElse(onFailure: (exception: Throwable) -> T): T {
        val error = result.exceptionOrNull()
        if (error != null) {
            error.throwIfFatal()
            return onFailure(error)
        }
        return result.getOrThrow()
    }

    fun getOrNull(): T? {
        val error = result.exceptionOrNull()
        if (error != null) {
            error.throwIfFatal()
            return null
        }
        return result.getOrNull()
    }

    fun getOrThrow(): T {
        return result.getOrThrow()
    }
}

inline fun <T> runCatchingNonFatal(block: () -> T): NonFatalResult<T> {
    return try {
        NonFatalResult(Result.success(block()))
    } catch (error: Throwable) {
        NonFatalResult(Result.failure(error))
    }
}

fun Throwable.throwIfFatal() {
    if (this !is Exception || this is CancellationException) {
        throw this
    }
}
//endregion

//region JSON
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
//endregion

//region ByteArray
fun ByteArray.decodeAsTextOrNull(): String? {
    if (hasBinaryControlBytes()) {
        return null
    }
    val decoder = StandardCharsets.UTF_8
        .newDecoder()
        .onMalformedInput(CodingErrorAction.REPORT)
        .onUnmappableCharacter(CodingErrorAction.REPORT)
    return runCatchingNonFatal {
        decoder.decode(ByteBuffer.wrap(this)).toString()
    }.onFailure {
        if (it !is CharacterCodingException) {
            throw it
        }
    }.getOrNull()
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
//endregion
