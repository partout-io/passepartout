// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.vpn

import android.content.Context
import android.util.AtomicFile
import com.algoritmico.passepartout.business.extensions.JSON
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AndroidConstants
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.context.lastTunnelPreferences
import com.algoritmico.passepartout.context.lastTunnelProfile
import com.algoritmico.passepartout.models.AppPreferences
import io.partout.models.TaggedProfile
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class VpnServiceStore(
    private val logTag: String,
    context: Context,
    private val storage: AndroidConstants.Storage
) {
    private val appContext = context.applicationContext

    private val lastProfileFile: File
        get() = appContext.lastTunnelProfile(storage)

    private val lastPreferencesFile: File
        get() = appContext.lastTunnelPreferences(storage)

    suspend fun readLastProfile(): String = withContext(Dispatchers.IO) {
        readLastFile(lastProfileFile)
    }

    suspend fun writeLastProfile(json: String) = withContext(Dispatchers.IO) {
        writeLastFile(lastProfileFile, json)
    }

    suspend fun deleteLastProfile(id: String) = withContext(Dispatchers.IO) {
        runCatchingNonFatal {
            val json = readLastFile(lastProfileFile)
            val profile = JSON.decode<TaggedProfile>(json)
            if (profile.id != id) { return@runCatchingNonFatal }
            AppLog.i(logTag, "Forget last profile $id")
            lastProfileFile.delete()
        }.onFailure {
            AppLog.w(logTag, "Unable to forget last profile", it)
        }
    }

    suspend fun readPreferences(intentPreferencesJSON: String?): AppPreferences? =
        withContext(Dispatchers.IO) {
            val preferencesJSON = if (intentPreferencesJSON.isNullOrBlank()) {
                AppLog.i(logTag, "Load last preferences")
                runCatchingNonFatal {
                    readLastFile(lastPreferencesFile)
                }.onFailure {
                    AppLog.w(logTag, "Unable to read last tunnel preferences", it)
                }.getOrNull()
            } else {
                AppLog.i(logTag, "Load and persist start preferences")
                runCatchingNonFatal {
                    writeLastFile(lastPreferencesFile, intentPreferencesJSON)
                }.onFailure {
                    AppLog.w(logTag, "Unable to write last tunnel preferences", it)
                }
                intentPreferencesJSON
            }
            preferencesJSON?.let(::decodePreferences)
        }

    private fun decodePreferences(json: String): AppPreferences? {
        return runCatchingNonFatal {
            JSON.decode<AppPreferences>(json)
        }.onFailure {
            AppLog.w(logTag, "Unable to decode preferences JSON", it)
        }.getOrNull()
    }

    private fun readLastFile(file: File): String {
        return AtomicFile(file).openRead().bufferedReader(Charsets.UTF_8).use {
            it.readText()
        }
    }

    private fun writeLastFile(file: File, json: String) {
        val atomicFile = AtomicFile(file)
        val stream = atomicFile.startWrite()
        runCatchingNonFatal {
            stream.write(json.toByteArray(Charsets.UTF_8))
            atomicFile.finishWrite(stream)
        }.onFailure {
            atomicFile.failWrite(stream)
            throw it
        }
    }
}
