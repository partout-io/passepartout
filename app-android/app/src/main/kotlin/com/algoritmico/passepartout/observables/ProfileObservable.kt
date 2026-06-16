// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import com.algoritmico.passepartout.managers.ProfileManager
import com.algoritmico.passepartout.models.AppFeature
import com.algoritmico.passepartout.models.AppProfileHeader
import com.algoritmico.passepartout.models.Event
import com.algoritmico.passepartout.models.ProfileEventChangeRemoteImporting
import com.algoritmico.passepartout.models.ProfileEventReady
import com.algoritmico.passepartout.models.ProfileEventRefresh
import com.algoritmico.passepartout.models.ProfileSharingFlag
import io.partout.models.TaggedProfile
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.io.Closeable

@OptIn(FlowPreview::class)
class ProfileObservable(
    private val manager: ProfileManager,
    coroutineScope: CoroutineScope,
    searchDebounceMillis: Long = 200L
) : Closeable {
    private val scope = CoroutineScope(
        coroutineScope.coroutineContext + SupervisorJob(coroutineScope.coroutineContext[Job])
    )

    private var allHeaders: Map<String, AppProfileHeader> = emptyMap()
    private val _state = MutableStateFlow(State())
    private val searchRequests = MutableStateFlow("")
    val state: StateFlow<State> = _state.asStateFlow()

    init {
        searchRequests
            .debounce(searchDebounceMillis)
            .onEach(::reloadHeaders)
            .launchIn(scope)

        manager.events
            .onEach(::onUpdate)
            .launchIn(scope)

        scope.launch {
            manager.loadInitialProfiles()
        }
    }

    fun search(name: String) {
        _state.update {
            it.copy(search = name)
        }
        searchRequests.value = name
    }

    fun onUpdate(event: Event) {
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

    fun profile(profileId: String): TaggedProfile? {
        return manager.profile(profileId)
    }

    suspend fun importText(text: String, filename: String) {
        manager.importText(text, filename)
    }

    suspend fun remove(profileId: String) {
        manager.remove(profileId)
    }

    suspend fun remove(profileIds: Collection<String>) {
        manager.remove(profileIds)
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
    }
}
