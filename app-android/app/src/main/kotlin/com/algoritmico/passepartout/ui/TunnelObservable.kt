// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import com.algoritmico.passepartout.abi.AppABITunnelProtocol
import com.algoritmico.passepartout.abi.models.AppProfileStatus
import com.algoritmico.passepartout.abi.models.AppTunnelInfo
import com.algoritmico.passepartout.abi.models.Event
import com.algoritmico.passepartout.abi.models.ProfileTransfer
import com.algoritmico.passepartout.abi.models.TunnelEventRefresh
import io.partout.abi.TaggedProfile
import io.partout.abi.TunnelSnapshot
import io.partout.jni.PartoutVpnServiceRuntime
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
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import java.io.Closeable

class TunnelObservable(
    private val abi: AppABITunnelProtocol,
    events: Flow<Event>,
    coroutineScope: CoroutineScope
) : Closeable {
    private val scope = CoroutineScope(
        coroutineScope.coroutineContext + SupervisorJob(coroutineScope.coroutineContext[Job])
    )

    private val _state = MutableStateFlow(State())
    private val _events = MutableSharedFlow<Event>(extraBufferCapacity = EVENT_BUFFER_CAPACITY)

    val events: SharedFlow<Event> = _events.asSharedFlow()
    val state: StateFlow<State> = _state.asStateFlow()

    init {
        events
            .onEach(::onUpdate)
            .launchIn(scope)
    }

    suspend fun connect(profile: TaggedProfile) {
        abi.connect(profile)
    }

    suspend fun disconnect(profileId: String) {
        abi.disconnect(profileId)
    }

    fun onUpdate(event: Event) {
        _events.tryEmit(event)
        when (event) {
            is TunnelEventRefresh -> {
                _state.update {
                    it.copy(activeProfiles = event.active)
                }
            }
            else -> {
                // Other app domains are intentionally ignored here.
            }
        }
    }

    fun activeProfile(): AppTunnelInfo? {
        return state.value.activeProfile
    }

    fun isActiveProfile(profileId: String): Boolean {
        return state.value.activeProfiles.containsKey(profileId)
    }

    fun status(profileId: String): AppProfileStatus {
        return state.value.activeProfiles[profileId]?.status ?: AppProfileStatus.disconnected
    }

    fun transfer(profileId: String): ProfileTransfer? {
        return state.value.activeProfiles[profileId]?.transfer
    }

    override fun close() {
        scope.cancel()
    }

    data class State(
        val activeProfiles: Map<String, AppTunnelInfo> = emptyMap()
    ) {
        val activeProfile: AppTunnelInfo?
            get() = activeProfiles.values.firstOrNull()

        val hasActiveProfiles: Boolean
            get() = activeProfiles.isNotEmpty()
    }

    private companion object {
        const val EVENT_BUFFER_CAPACITY = 64
    }
}
