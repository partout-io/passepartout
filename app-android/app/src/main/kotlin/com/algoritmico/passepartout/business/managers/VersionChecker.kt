// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.managers

import com.algoritmico.passepartout.context.AppLog
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import com.algoritmico.passepartout.business.extensions.LastCheckedVersionSnapshot
import com.algoritmico.passepartout.business.extensions.compareTo
import com.algoritmico.passepartout.business.extensions.lastCheckedVersionSnapshots
import com.algoritmico.passepartout.business.extensions.max
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.extensions.toSemanticVersionOrNull
import com.algoritmico.passepartout.business.extensions.updateLastCheckedVersion
import com.algoritmico.passepartout.business.extensions.versionString
import com.algoritmico.passepartout.context.newEventFlow
import com.algoritmico.passepartout.models.ChangelogEntry
import com.algoritmico.passepartout.models.Event
import com.algoritmico.passepartout.models.SemanticVersion
import com.algoritmico.passepartout.models.VersionEventNew
import com.algoritmico.passepartout.models.VersionRelease
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.sync.Mutex
import java.io.Closeable

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
    coroutineScope: CoroutineScope,
    private val strategy: VersionCheckerStrategy = DummyVersionCheckerStrategy(),
    currentVersion: String = "255.255.255",
    private val downloadURL: String = "http://"
) : Closeable {
    private val mutex = Mutex()
    private val scope = CoroutineScope(
        coroutineScope.coroutineContext + SupervisorJob(coroutineScope.coroutineContext[Job])
    )
    private val snapshots = store.lastCheckedVersionSnapshots(logTag)
        .map { VersionSnapshotState.Ready(it) }
        .stateIn(scope, SharingStarted.Eagerly, VersionSnapshotState.Loading)
    private val currentVersion = currentVersion.toSemanticVersionOrNull() ?: SemanticVersion.max
    private val _events = newEventFlow()
    val events: SharedFlow<Event> = _events.asSharedFlow()

    val latestRelease: VersionRelease?
        get() {
            val latestVersionDescription = currentSnapshot()?.version ?: return null
            val latestVersion = latestVersionDescription.toSemanticVersionOrNull() ?: return null
            return latestVersion.release()
        }

    suspend fun checkLatestRelease() {
        if (!mutex.tryLock()) {
            return
        }
        runCatchingNonFatal {
            val now = System.currentTimeMillis()
            val release = runCatchingNonFatal {
                newReleaseOrNull(now)
            }.onFailure {
                handleVersionCheckFailure(now, it)
            }.getOrElse {
                latestRelease
            }
            if (release == null) {
                AppLog.d(logTag, "Version: current is latest version")
            } else {
                AppLog.i(logTag, "Version: new version available at ${release.url}")
                _events.emit(VersionEventNew(release = release))
            }
        }.also {
            mutex.unlock()
        }.getOrThrow()
    }

    suspend fun fetchChangelog(version: String): List<ChangelogEntry> {
        return strategy.fetchChangelog(version)
    }

    override fun close() {
        scope.cancel()
    }

    private suspend fun newReleaseOrNull(timestamp: Long): VersionRelease? {
        val lastCheckedTimestamp = waitForSnapshot()?.timestamp
        AppLog.d(logTag, "Version: checking for updates...")
        val fetchedLatestVersion = strategy.latestVersion(lastCheckedTimestamp)
        saveVersion(timestamp, fetchedLatestVersion.versionString)
        AppLog.i(
            logTag,
            "Version: ${fetchedLatestVersion.versionString} > " +
                    "${currentVersion.versionString} = ${fetchedLatestVersion > currentVersion}"
        )
        return fetchedLatestVersion.release()
    }

    private suspend fun handleVersionCheckFailure(timestamp: Long, error: Throwable) {
        when (error) {
            is VersionCheckerException.RateLimit -> AppLog.d(logTag, "Version: rate limit")
            is VersionCheckerException.UnexpectedResponse -> {
                saveVersion(timestamp, null)
                AppLog.e(logTag, "Unable to check version", error)
            }
            else -> AppLog.e(logTag, "Unable to check version", error)
        }
    }

    private suspend fun saveVersion(timestamp: Long, version: String?) {
        store.updateLastCheckedVersion(timestamp, version)
    }

    private fun currentSnapshot(): LastCheckedVersionSnapshot? {
        return when (val state = snapshots.value) {
            is VersionSnapshotState.Ready -> state.snapshot
            VersionSnapshotState.Loading -> null
        }
    }

    private suspend fun waitForSnapshot(): LastCheckedVersionSnapshot? {
        return when (val state = snapshots.value) {
            is VersionSnapshotState.Ready -> state.snapshot
            VersionSnapshotState.Loading -> {
                (snapshots.first { it is VersionSnapshotState.Ready } as VersionSnapshotState.Ready)
                    .snapshot
            }
        }
    }

    private fun SemanticVersion.release(): VersionRelease? {
        if (this <= currentVersion) {
            return null
        }
        return VersionRelease(version = this, url = downloadURL)
    }
}

private sealed class VersionSnapshotState {
    data object Loading : VersionSnapshotState()
    data class Ready(val snapshot: LastCheckedVersionSnapshot?) : VersionSnapshotState()
}

private class DummyVersionCheckerStrategy : VersionCheckerStrategy {
    override suspend fun latestVersion(sinceTimestamp: Long?): SemanticVersion {
        return SemanticVersion(255, 255, 255)
    }

    override suspend fun fetchChangelog(version: String): List<ChangelogEntry> {
        return emptyList()
    }
}
