// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.content.Intent
import android.util.Log
import com.algoritmico.passepartout.PassepartoutVpnService
import com.algoritmico.passepartout.injection.JSON
import com.algoritmico.passepartout.managers.ProfileManager
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.models.AppProfileStatus
import com.algoritmico.passepartout.models.AppTunnelInfo
import com.algoritmico.passepartout.models.Event
import com.algoritmico.passepartout.models.ProfileEventDelete
import com.algoritmico.passepartout.models.ProfileTransfer
import io.partout.PartoutTunnel
import io.partout.extensions.isInteractive
import io.partout.models.TaggedProfile
import io.partout.models.TunnelSnapshot
import io.partout.models.TunnelStatus
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.suspendCancellableCoroutine
import java.io.Closeable
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class TunnelObservable(
    private val logTag: String,
    private val tunnel: PartoutTunnel,
    profileManager: ProfileManager,
    preferences: Flow<AppPreferences>,
    coroutineScope: CoroutineScope
) : Closeable {
    private val scope = CoroutineScope(
        coroutineScope.coroutineContext + SupervisorJob(coroutineScope.coroutineContext[Job])
    )

    private val _state = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()
    private var pendingConnectContinuation: CancellableContinuation<Unit>? = null

    init {
        tunnel.state
            .onEach(::onTunnelState)
            .launchIn(scope)

        profileManager.events
            .onEach(::onUpdate)
            .launchIn(scope)
    }

    suspend fun connect(profile: TaggedProfile, force: Boolean = false) {
        if (!force && profile.isInteractive) {
            throw InteractiveException(profile)
        }
        suspendCancellableCoroutine { continuation ->
            pendingConnectContinuation = continuation
            continuation.invokeOnCancellation {
                if (pendingConnectContinuation == continuation) {
                    pendingConnectContinuation = null
                }
            }
            tunnel.connect(profile, onConnectIntent) callback@ { status ->
                if (!continuation.isActive) { return@callback }
                if (pendingConnectContinuation == continuation) {
                    pendingConnectContinuation = null
                }
                if (status != PartoutTunnel.ERROR_NONE) {
                    continuation.resumeWithException(TunnelException)
                    return@callback
                }
                continuation.resume(Unit)
            }
        }
    }

    private val onConnectIntent: (Intent) -> Unit = { intent ->
        val json = runBlocking {
            val prefs = preferences.first()
            JSON.encode(prefs)
        }
        intent.putExtra(PassepartoutVpnService.EXTRA_TUNNEL_PREFERENCES, json)
    }

    suspend fun disconnect(profileId: String) =
        suspendCancellableCoroutine { continuation ->
            tunnel.disconnect(profileId) callback@ { status ->
                if (!continuation.isActive) {
                    return@callback
                }
                if (status != PartoutTunnel.ERROR_NONE) {
                    continuation.resumeWithException(TunnelException)
                    return@callback
                }
                continuation.resume(Unit)
            }
        }

    suspend fun getEnvironmentValue(name: String): String? {
        val json = tunnel.requestEnvironmentValue(name)
        Log.i(logTag, "TunnelObservable.getEnvironmentValue($name) = $json")
        return json
    }

    fun onVpnPermissionResult(isGranted: Boolean) {
        if (isGranted) {
            tunnel.onVpnPermissionResult(true)
            return
        }

        _state.update {
            it.copy(isVpnPermissionDenied = true)
        }
        pendingConnectContinuation?.let { continuation ->
            pendingConnectContinuation = null
            if (continuation.isActive) {
                continuation.resumeWithException(VpnPermissionDeniedException())
            }
        }
    }

    fun clearVpnPermissionDenied() {
        _state.update {
            it.copy(isVpnPermissionDenied = false)
        }
    }

    private fun onTunnelState(tunnelState: PartoutTunnel.State) {
        _state.update {
            it.copy(activeProfiles = tunnelState.snapshots.mapValues {
                it.value.toAppTunnelInfo()
            })
        }
    }

    private fun onUpdate(event: Event) {
        if (event !is ProfileEventDelete) { return }
        event.ids.forEach {
            Log.i(logTag, "Disconnect from removed profile $it")
            tunnel.disconnect(it, forget = true) { _ -> }
        }
    }

    override fun close() {
        scope.cancel()
        tunnel.close()
    }

    data class State(
        val activeProfiles: Map<String, AppTunnelInfo> = emptyMap(),
        val isVpnPermissionDenied: Boolean = false
    )

    data object TunnelException: Exception()
    class InteractiveException(val profile: TaggedProfile): Exception()
    private class VpnPermissionDeniedException: Exception()

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
