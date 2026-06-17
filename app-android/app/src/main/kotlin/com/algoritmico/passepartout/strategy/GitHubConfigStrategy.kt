// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.strategy

import android.os.SystemClock
import android.util.Log
import com.algoritmico.passepartout.managers.ConfigBundle
import com.algoritmico.passepartout.managers.ConfigManagerException
import com.algoritmico.passepartout.managers.ConfigManagerStrategy

class GitHubConfigStrategy(
    private val logTag: String,
    private val url: String,
    private val ttl: Double,
    private val fetcher: suspend (String) -> ByteArray
) : ConfigManagerStrategy {
    private var lastUpdatedAtMillis: Long? = null

    override suspend fun bundle(): ConfigBundle {
        val now = SystemClock.elapsedRealtime()
        lastUpdatedAtMillis?.let { lastUpdatedAtMillis ->
            val elapsed = (now - lastUpdatedAtMillis) / 1000.0
            if (elapsed < ttl) {
                Log.d(logTag, "Config (GitHub): elapsed $elapsed < $ttl")
                throw ConfigManagerException.RateLimit
            }
        }

        Log.i(logTag, "Config (GitHub): fetching bundle from $url")
        val data = fetcher(url)
        val bundle = ConfigBundle.decode(data)
        lastUpdatedAtMillis = SystemClock.elapsedRealtime()
        return bundle
    }
}
