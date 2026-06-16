// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import com.algoritmico.passepartout.managers.VersionChecker
import com.algoritmico.passepartout.models.ChangelogEntry
import com.algoritmico.passepartout.models.Event
import com.algoritmico.passepartout.models.VersionEventNew
import com.algoritmico.passepartout.models.VersionRelease
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import java.io.Closeable

class VersionObservable(
    private val manager: VersionChecker,
    coroutineScope: CoroutineScope
) : Closeable {
    private val scope = CoroutineScope(
        coroutineScope.coroutineContext + SupervisorJob(coroutineScope.coroutineContext[Job])
    )

    private val _state = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()

    init {
        manager.events
            .onEach(::onUpdate)
            .launchIn(scope)
    }

    private fun onUpdate(event: Event) {
        when (event) {
            is VersionEventNew -> {
                _state.update {
                    it.copy(latestRelease = event.release)
                }
            }
            else -> {
                // Other app domains are intentionally ignored here.
            }
        }
    }

    suspend fun fetchChangelog(version: String): List<ChangelogEntry> {
        return manager.fetchChangelog(version)
    }

    override fun close() {
        scope.cancel()
    }

    data class State(
        val latestRelease: VersionRelease? = null
    )
}
