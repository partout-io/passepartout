// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.managers

import android.util.Log
import com.algoritmico.passepartout.extensions.Globals
import com.algoritmico.passepartout.extensions.versionString
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.models.ChangelogEntry
import com.algoritmico.passepartout.models.Event
import com.algoritmico.passepartout.models.SemanticVersion
import com.algoritmico.passepartout.models.VersionEventNew
import com.algoritmico.passepartout.models.VersionRelease
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.sync.Mutex

interface VersionCheckerStrategy {
    suspend fun latestVersion(sinceTimestamp: Long?): SemanticVersion
}

class VersionChecker(
    private val logTag: String,
    private val preferences: () -> AppPreferences = { AppPreferences.default },
    private val updatePreferences: suspend (
        fields: List<AppPreferenceKey>,
        transform: (AppPreferences) -> AppPreferences
    ) -> Unit = { _, _ -> },
    private val strategy: VersionCheckerStrategy = DummyVersionCheckerStrategy(),
    currentVersion: String = "255.255.255",
    private val downloadURL: String = "http://",
    private val changelogFetcher: suspend (String) -> List<ChangelogEntry> = { emptyList() }
) {
    private val currentVersion = currentVersion.toSemanticVersionOrNull()
        ?: error("Unparsable current version: $currentVersion")

    private val checkMutex = Mutex()

    private val _events = MutableSharedFlow<Event>(
        replay = Globals.EVENT_REPLAY,
        extraBufferCapacity = Globals.EVENT_BUFFER_CAPACITY
    )
    val events: SharedFlow<Event> = _events.asSharedFlow()

    val latestRelease: VersionRelease?
        get() {
            val latestVersionDescription = preferences().lastCheckedVersion ?: return null
            val latestVersion = latestVersionDescription.toSemanticVersionOrNull() ?: return null
            return if (latestVersion > currentVersion) {
                VersionRelease(
                    version = latestVersion,
                    url = downloadURL
                )
            } else {
                null
            }
        }

    suspend fun checkLatestRelease() {
        if (!checkMutex.tryLock()) {
            return
        }
        try {
            val now = System.currentTimeMillis()
            try {
                val lastCheckedTimestamp = preferences().lastCheckedVersionTimestamp

                Log.d(logTag, "Version: checking for updates...")
                val fetchedLatestVersion = strategy.latestVersion(lastCheckedTimestamp)
                updatePreferences(
                    listOf(
                        AppPreferenceKey.lastCheckedVersion,
                        AppPreferenceKey.lastCheckedVersionDate
                    )
                ) {
                    it.copy(
                        lastCheckedVersionTimestamp = now,
                        lastCheckedVersion = fetchedLatestVersion.versionString
                    )
                }
                Log.i(
                    logTag,
                    "Version: ${fetchedLatestVersion.versionString} > " +
                        "${currentVersion.versionString} = ${fetchedLatestVersion > currentVersion}"
                )
            } catch (_: VersionCheckerRateLimitException) {
                Log.d(logTag, "Version: rate limit")
            } catch (error: VersionCheckerUnexpectedResponseException) {
                updatePreferences(listOf(AppPreferenceKey.lastCheckedVersionDate)) {
                    it.copy(lastCheckedVersionTimestamp = now)
                }
                Log.e(logTag, "Unable to check version", error)
            } catch (error: CancellationException) {
                throw error
            } catch (error: Throwable) {
                Log.e(logTag, "Unable to check version", error)
            }

            val latestRelease = latestRelease
            if (latestRelease == null) {
                Log.d(logTag, "Version: current is latest version")
                return
            }
            Log.i(logTag, "Version: new version available at ${latestRelease.url}")
            _events.emit(VersionEventNew(release = latestRelease))
        } finally {
            checkMutex.unlock()
        }
    }

    suspend fun fetchChangelog(version: String): List<ChangelogEntry> {
        return changelogFetcher(version)
    }
}

class VersionCheckerRateLimitException : Exception()

class VersionCheckerUnexpectedResponseException : Exception()

private class DummyVersionCheckerStrategy : VersionCheckerStrategy {
    override suspend fun latestVersion(sinceTimestamp: Long?): SemanticVersion {
        return SemanticVersion(255, 255, 255)
    }
}

fun String.toSemanticVersionOrNull(): SemanticVersion? {
    val parts = split(".")
    if (parts.size != 3) {
        return null
    }
    val major = parts[0].toIntOrNull() ?: return null
    val minor = parts[1].toIntOrNull() ?: return null
    val patch = parts[2].toIntOrNull() ?: return null
    return SemanticVersion(major, minor, patch)
}

private operator fun SemanticVersion.compareTo(other: SemanticVersion): Int {
    return encodedValue().compareTo(other.encodedValue())
}

private fun SemanticVersion.encodedValue(): Int {
    return ((major and 0xff) shl 16) + ((minor and 0xff) shl 8) + (patch and 0xff)
}
