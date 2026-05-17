// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import com.algoritmico.passepartout.abi.models.AppProfileStatus
import com.algoritmico.passepartout.abi.models.AppTunnelInfo
import com.algoritmico.passepartout.abi.models.ProfileTransfer
import io.partout.PartoutTunnel
import io.partout.models.TaggedProfile
import io.partout.models.TunnelSnapshot
import io.partout.models.TunnelStatus
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.withContext
import java.io.Closeable

class TunnelObservable(
    private val tunnel: PartoutTunnel,
    coroutineScope: CoroutineScope
) : Closeable {
    private val scope = CoroutineScope(
        coroutineScope.coroutineContext + SupervisorJob(coroutineScope.coroutineContext[Job])
    )

    private val _state = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()

    init {
        tunnel.state
            .onEach(::onUpdate)
            .launchIn(scope)
    }

    suspend fun connect(profile: TaggedProfile) {
        withContext(Dispatchers.IO) {
            tunnel.connect(profile) { status ->
                if (status != PartoutTunnel.ERROR_NONE) {
                    throw TunnelException
                }
            }
        }
    }

    suspend fun disconnect(profileId: String) {
        withContext(Dispatchers.IO) {
            tunnel.disconnect(profileId) { status ->
                if (status != PartoutTunnel.ERROR_NONE) {
                    throw TunnelException
                }
            }
        }
    }

    private fun onUpdate(tunnelState: PartoutTunnel.State) {
        _state.update {
            it.copy(activeProfiles = tunnelState.snapshots.mapValues {
                it.value.toAppTunnelInfo()
            })
        }
    }

    override fun close() {
        scope.cancel()
    }

    data class State(
        val activeProfiles: Map<String, AppTunnelInfo> = emptyMap()
    )

    data object TunnelException: Throwable()

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
