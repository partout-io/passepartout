// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.strategy

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

object URLFetcher {
    suspend fun fetch(url: String, cached: Boolean, timeout: Double): ByteArray {
        return withContext(Dispatchers.IO) {
            fetchBlocking(url, cached, timeout)
        }
    }

    private fun fetchBlocking(url: String, cached: Boolean, timeout: Double): ByteArray {
        val connection = URL(url).openConnection() as HttpURLConnection
        return runCatching {
            connection.requestMethod = "GET"
            connection.useCaches = cached
            connection.connectTimeout = timeout.toInt() * 1000
            connection.readTimeout = timeout.toInt() * 1000
            val status = connection.responseCode
            if (status !in 200..299) {
                throw IOException("HTTP $status")
            }
            connection.inputStream.use { it.readBytes() }
        }.also {
            connection.disconnect()
        }.getOrThrow()
    }
}
