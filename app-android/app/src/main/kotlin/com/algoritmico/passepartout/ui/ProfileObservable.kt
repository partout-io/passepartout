// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import com.algoritmico.passepartout.abi.AppABIProfileProtocol
import com.algoritmico.passepartout.abi.models.AppFeature
import com.algoritmico.passepartout.abi.models.AppProfileHeader
import com.algoritmico.passepartout.abi.models.Event
import com.algoritmico.passepartout.abi.models.ProfileEventChangeRemoteImporting
import com.algoritmico.passepartout.abi.models.ProfileEventReady
import com.algoritmico.passepartout.abi.models.ProfileEventRefresh
import com.algoritmico.passepartout.abi.models.ProfileSharingFlag
import io.partout.abi.TaggedProfile
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import java.io.Closeable

class ProfileObservable(
    events: Flow<Event>,
    private val abi: AppABIProfileProtocol,
    coroutineScope: CoroutineScope,
    searchDebounceMillis: Long = 200L
) : Closeable {
    private val scope = CoroutineScope(
        coroutineScope.coroutineContext + SupervisorJob(coroutineScope.coroutineContext[Job])
    )

    private var allHeaders: Map<String, AppProfileHeader> = emptyMap()
    private val _state = MutableStateFlow(State())
    private val searchRequests = MutableStateFlow("")
    private val _events = MutableSharedFlow<Event>(extraBufferCapacity = EVENT_BUFFER_CAPACITY)

    val events: SharedFlow<Event> = _events.asSharedFlow()
    val state: StateFlow<State> = _state.asStateFlow()

    init {
        events
            .onEach(::onUpdate)
            .launchIn(scope)

        searchRequests
            .debounce(searchDebounceMillis)
            .onEach(::reloadHeaders)
            .launchIn(scope)
    }

    fun search(name: String) {
        _state.update {
            it.copy(search = name)
        }
        searchRequests.value = name
    }

    fun onUpdate(event: Event) {
        _events.tryEmit(event)
        when (event) {
            is ProfileEventReady -> {
                _state.update {
                    it.copy(isReady = true)
                }
            }

            is ProfileEventRefresh -> {
                allHeaders = event.headers
                reloadHeaders(search = state.value.search)
            }

            is ProfileEventChangeRemoteImporting -> {
                _state.update {
                    it.copy(isRemoteImportingEnabled = event.isImporting)
                }
            }

            else -> {
                // Other app domains are intentionally ignored here.
            }
        }
    }

    fun header(profileId: String): AppProfileHeader? {
        return allHeaders[profileId]
    }

    suspend fun profile(profileId: String): TaggedProfile? {
        return abi.profile(profileId)
    }

    suspend fun importText(text: String, filename: String) {
        abi.importText(text, filename)
    }

    suspend fun remove(profileId: String) {
        abi.remove(profileId)
    }

    suspend fun remove(profileIds: Collection<String>) {
        abi.remove(profileIds)
    }

    suspend fun removeAll() {
        remove(state.value.filteredHeaders.map { it.id })
    }

    fun firstUniqueName(name: String): String {
        val allNames = allHeaders.values.map { it.name }.toSet()
        var candidate = name
        var index = 1
        while (candidate in allNames) {
            candidate = "$name.$index"
            index += 1
        }
        return candidate
    }

    fun isRemotelyShared(profileId: String): Boolean {
        return allHeaders[profileId]?.sharingFlags?.isNotEmpty() == true
    }

    fun sharingFlags(profileId: String): List<ProfileSharingFlag> {
        return allHeaders[profileId]?.sharingFlags.orEmpty()
    }

    fun requiredFeatures(profileId: String): Set<AppFeature>? {
        return allHeaders[profileId]?.requiredFeatures?.toSet()
    }

    override fun close() {
        scope.cancel()
    }

    private fun reloadHeaders(search: String) {
        _state.update {
            it.copy(filteredHeaders = allHeaders.filtered(search = search))
        }
    }

    data class State(
        val filteredHeaders: List<AppProfileHeader> = emptyList(),
        val isReady: Boolean = false,
        val isRemoteImportingEnabled: Boolean = false,
        val search: String = ""
    ) {
        val hasProfiles: Boolean
            get() = filteredHeaders.isNotEmpty()

        val isSearching: Boolean
            get() = search.isNotEmpty()
    }

    private companion object {
        fun Map<String, AppProfileHeader>.filtered(search: String): List<AppProfileHeader> {
            val normalizedSearch = search.lowercase()
            return values
                .filter { header ->
                    normalizedSearch.isEmpty() || header.name.lowercase().contains(normalizedSearch)
                }
                .sortedBy { it.name.lowercase() }
        }

        const val EVENT_BUFFER_CAPACITY = 64
    }
}
