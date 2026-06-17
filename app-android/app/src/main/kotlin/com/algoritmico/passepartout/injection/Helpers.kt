// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.injection

import android.util.Log
import androidx.compose.ui.platform.UriHandler
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.encodeToJsonElement

fun UriHandler.safeOpenUri(uri: String) {
    runCatching {
        openUri(uri)
    }.onFailure {
        Log.e(Tags.APP, "Unable to open URL ($uri)", it)
        // FIXME: ###, Generic error alert
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
