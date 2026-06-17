// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.managers

import android.util.Log
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import com.algoritmico.passepartout.business.extensions.throwIfCancellation
import com.algoritmico.passepartout.business.extensions.toAppPreferences
import com.algoritmico.passepartout.business.extensions.update
import com.algoritmico.passepartout.business.extensions.versionString
import com.algoritmico.passepartout.context.newEventFlow
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.ChangelogEntry
import com.algoritmico.passepartout.models.Event
import com.algoritmico.passepartout.models.SemanticVersion
import com.algoritmico.passepartout.models.VersionEventNew
import com.algoritmico.passepartout.models.VersionRelease
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.sync.Mutex

data class VersionCheckerSnapshot(
    val timestamp: Long,
    val version: String?
)

interface VersionCheckerStrategy {
    suspend fun latestVersion(sinceTimestamp: Long?): SemanticVersion
    suspend fun fetchChangelog(version: String): List<ChangelogEntry>
}

sealed class VersionCheckerException: Exception() {
    data object RateLimit: VersionCheckerException()
    data object UnexpectedResponse: VersionCheckerException()
}

class VersionChecker(
    private val logTag: String,
    private val store: DataStore<Preferences>,
    private val strategy: VersionCheckerStrategy = DummyVersionCheckerStrategy(),
    currentVersion: String = "255.255.255",
    private val downloadURL: String = "http://"
) {
    private val currentVersion = currentVersion.toSemanticVersionOrNull() ?: SemanticVersion(
        0,
        0,
        0
    )
    private val checkMutex = Mutex()

    private val _events = newEventFlow()
    val events: SharedFlow<Event> = _events.asSharedFlow()

    val latestRelease: VersionRelease?
        get() {
            val latestVersionDescription = onLastSnapshot()?.version ?: return null
            val latestVersion = latestVersionDescription.toSemanticVersionOrNull() ?: return null
            if (latestVersion <= currentVersion) {
                return null
            }
            return VersionRelease(version = latestVersion, url = downloadURL)
        }

    suspend fun checkLatestRelease() {
        if (!checkMutex.tryLock()) {
            return
        }
        runCatching {
            val now = System.currentTimeMillis()
            runCatching {
                val lastCheckedTimestamp = onLastSnapshot()?.timestamp
                Log.d(logTag, "Version: checking for updates...")
                val fetchedLatestVersion = strategy.latestVersion(lastCheckedTimestamp)
                onSaveVersion(now, fetchedLatestVersion.versionString)
                Log.i(
                    logTag,
                    "Version: ${fetchedLatestVersion.versionString} > " +
                        "${currentVersion.versionString} = ${fetchedLatestVersion > currentVersion}"
                )
            }.onFailure {
                it.throwIfCancellation()
                when (it) {
                    is VersionCheckerException.RateLimit -> Log.d(logTag, "Version: rate limit")
                    is VersionCheckerException.UnexpectedResponse -> {
                        onSaveVersion(now, null)
                        Log.e(logTag, "Unable to check version", it)
                    }
                    else -> Log.e(logTag, "Unable to check version", it)
                }
            }

            val latestRelease = latestRelease
            if (latestRelease == null) {
                Log.d(logTag, "Version: current is latest version")
                return
            }
            Log.i(logTag, "Version: new version available at ${latestRelease.url}")
            _events.emit(VersionEventNew(release = latestRelease))
        }.also {
            checkMutex.unlock()
        }.getOrThrow()
    }

    suspend fun fetchChangelog(version: String): List<ChangelogEntry> {
        return strategy.fetchChangelog(version)
    }

    private suspend fun onSaveVersion(timestamp: Long, version: String?) {
        val fields = listOf(
            AppPreferenceKey.lastCheckedVersion,
            AppPreferenceKey.lastCheckedVersionDate
        )
        store.edit {
            val current = it.toAppPreferences()
            val newValue = current.copy(
                lastCheckedVersionTimestamp = timestamp,
                lastCheckedVersion = version ?: current.lastCheckedVersion
            )
            it.update(fields, newValue)
        }
    }

    private fun onLastSnapshot(): VersionCheckerSnapshot? {
        val snapshot = runBlocking {
            store.data.first().toAppPreferences()
        }
        val timestamp = snapshot.lastCheckedVersionTimestamp ?: return null
        return VersionCheckerSnapshot(timestamp, snapshot.lastCheckedVersion)
    }
}

fun String.toSemanticVersionOrNull(): SemanticVersion? {
    return runCatching {
        val parts = split(".")
        require(parts.size == 3)
        val major = parts[0].toInt()
        val minor = parts[1].toInt()
        val patch = parts[2].toInt()
        SemanticVersion(major, minor, patch)
    }.getOrNull()
}

private operator fun SemanticVersion.compareTo(other: SemanticVersion): Int {
    return encodedValue().compareTo(other.encodedValue())
}

private fun SemanticVersion.encodedValue(): Int {
    return ((major and 0xff) shl 16) + ((minor and 0xff) shl 8) + (patch and 0xff)
}

private class DummyVersionCheckerStrategy : VersionCheckerStrategy {
    override suspend fun latestVersion(sinceTimestamp: Long?): SemanticVersion {
        return SemanticVersion(255, 255, 255)
    }

    override suspend fun fetchChangelog(version: String): List<ChangelogEntry> {
        return emptyList()
    }
}
