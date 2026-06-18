// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.LocalConstants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

class DiagnosticsObservable {
    suspend fun logcat(
        tags: Collection<String>,
        hours: Long
    ): List<String> = coroutineScope {
        val process = withContext(Dispatchers.IO) {
            ProcessBuilder(logcatCommand(tags, hours))
                .redirectErrorStream(true)
                .start()
        }
        val output = async(Dispatchers.IO) {
            process.inputStream.bufferedReader().use {
                it.readLines()
            }
        }
        runCatchingNonFatal {
            val timeoutMillis = logTimeoutMillis
            val didFinish = withContext(Dispatchers.IO) {
                process.waitFor(timeoutMillis, TimeUnit.MILLISECONDS)
            }
            if (!didFinish) {
                process.destroy()
                if (!process.waitFor(LocalConstants.LOGCAT_DESTROY_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS)) {
                    process.destroyForcibly()
                }
                error("logcat timed out")
            }

            val lines = output.await()
            val exitCode = process.exitValue()
            if (exitCode != 0) {
                error("logcat exited with status $exitCode")
            }
            lines
        }.also {
            if (process.isAlive) {
                process.destroyForcibly()
            }
            output.cancel()
        }.getOrElse {
            throw it
        }
    }

    private val logTimeoutMillis: Long
        get() = (LocalConstants.LOGCAT_TIMEOUT_SECONDS * 1000.0)
            .toLong()
            .coerceAtLeast(1L)

    private fun logcatCommand(
        tags: Collection<String>,
        hours: Long
    ): List<String> {
        val since = Date(System.currentTimeMillis() - TimeUnit.HOURS.toMillis(hours))
        val sinceString = SimpleDateFormat("MM-dd HH:mm:ss.SSS", Locale.US).format(since)
        return listOf(
            "logcat",
            "-d",
            "-T",
            sinceString,
            "-v",
            "time"
        ) + tags.map {
            "$it:V"
        } + "*:S"
    }
}
