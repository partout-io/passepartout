// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import android.util.Log
import com.algoritmico.passepartout.abi.models.AppProfileStatus
import com.algoritmico.passepartout.abi.models.AppTunnelInfo
import com.algoritmico.passepartout.abi.models.Event
import com.algoritmico.passepartout.abi.models.ProfileEventRefresh
import com.algoritmico.passepartout.abi.models.ProfileTransfer
import io.partout.PartoutTunnel
import io.partout.models.TaggedProfile
import io.partout.models.TunnelSnapshot
import io.partout.models.TunnelStatus
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.suspendCancellableCoroutine
import java.io.Closeable
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class TunnelObservable(
    private val logTag: String,
    private val tunnel: PartoutTunnel,
    events: Flow<Event>,
    coroutineScope: CoroutineScope
) : Closeable {
    private val scope = CoroutineScope(
        coroutineScope.coroutineContext + SupervisorJob(coroutineScope.coroutineContext[Job])
    )

    private val _state = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()

    init {
        tunnel.state
            .onEach(::onTunnelState)
            .launchIn(scope)

        events
            .onEach(::onUpdate)
            .launchIn(scope)
    }

    suspend fun connect(profile: TaggedProfile) {
        suspendCancellableCoroutine { continuation ->
            tunnel.connect(profile) callback@ { status ->
                if (!continuation.isActive) { return@callback }
                if (status != PartoutTunnel.ERROR_NONE) {
                    continuation.resumeWithException(TunnelException)
                    return@callback
                }
                continuation.resume(Unit)
            }
        }
    }

    suspend fun disconnect(profileId: String) {
        suspendCancellableCoroutine { continuation ->
            tunnel.disconnect(profileId) callback@ { status ->
                if (!continuation.isActive) { return@callback }
                if (status != PartoutTunnel.ERROR_NONE) {
                    continuation.resumeWithException(TunnelException)
                    return@callback
                }
                continuation.resume(Unit)
            }
        }
    }

    fun onVpnPermissionResult(isGranted: Boolean) {
        tunnel.onVpnPermissionResult(isGranted)
    }

    private fun onTunnelState(tunnelState: PartoutTunnel.State) {
        _state.update {
            it.copy(activeProfiles = tunnelState.snapshots.mapValues {
                it.value.toAppTunnelInfo()
            })
        }
    }

    private fun onUpdate(event: Event) {
        when (event) {
            is ProfileEventRefresh -> {
                // Iterate through active tunnel
                state.value.activeProfiles.forEach {
                    val info = it.value
                    // Ignore profiles that were not deleted
                    if (info.id in event.headers) {
                        return@forEach
                    }
                    // Ignore deletion of inactive profiles
                    if (!info.status.isActive) {
                        return@forEach
                    }
                    Log.i(logTag, "Disconnect from removed profile ${info.id}")
                    tunnel.disconnect(info.id) { _ -> }
                }
            }
            else -> {}
        }
    }

    override fun close() {
        tunnel.close()
        scope.cancel()
    }

    data class State(
        val activeProfiles: Map<String, AppTunnelInfo> = emptyMap()
    )

    data object TunnelException: Throwable()

    private val AppProfileStatus.isActive: Boolean
        get() = this == AppProfileStatus.connecting || this == AppProfileStatus.connected

    private fun TunnelSnapshot.toAppTunnelInfo(): AppTunnelInfo {
        return AppTunnelInfo(
            id = id,
            isEnabled = isEnabled,
            status = appStatus(),
            onDemand = onDemand,
            transfer = environment?.dataCount?.let {
                ProfileTransfer(
                    received = it.received,
                    sent = it.sent
                )
            },
            lastErrorCode = environment?.lastErrorCode
        )
    }

    // On Android tunnel status == connection status
    private fun TunnelSnapshot.appStatus(): AppProfileStatus {
        return when (status) {
            TunnelStatus.inactive -> AppProfileStatus.disconnected
            TunnelStatus.activating -> AppProfileStatus.connecting
            TunnelStatus.active -> AppProfileStatus.connected
            TunnelStatus.deactivating -> AppProfileStatus.disconnecting
        }
    }
}
