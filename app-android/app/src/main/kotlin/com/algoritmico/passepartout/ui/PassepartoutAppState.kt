// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.algoritmico.passepartout.abi.models.AppProfileHeader
import com.algoritmico.passepartout.abi.models.AppProfileStatus
import com.algoritmico.passepartout.abi.models.AppTunnelInfo
import com.algoritmico.passepartout.abi.models.Event
import com.algoritmico.passepartout.abi.models.ProfileEventRefresh
import com.algoritmico.passepartout.abi.models.ProfileEventSave
import com.algoritmico.passepartout.abi.models.TunnelEventRefresh

@Composable
fun rememberPassepartoutAppState(): PassepartoutAppState {
    return remember {
        PassepartoutAppState()
    }
}

@Stable
class PassepartoutAppState {
    private var headers by mutableStateOf<Map<String, AppProfileHeader>>(emptyMap())
    private var activeTunnels by mutableStateOf<Map<String, AppTunnelInfo>>(emptyMap())
    private var requestedConnection by mutableStateOf<RequestedConnection?>(null)

    var selectedProfileId by mutableStateOf<String?>(null)
        private set

    fun updateProfiles(headers: Map<String, AppProfileHeader>) {
        this.headers = headers
        val sortedIds = headers.values.sortedBy { it.name.lowercase() }.map { it.id }
        if (selectedProfileId !in sortedIds) {
            selectedProfileId = sortedIds.firstOrNull()
        }
    }

    fun updateActiveTunnels(activeTunnels: Map<String, AppTunnelInfo>) {
        val hadActiveTunnels = this.activeTunnels.isNotEmpty()
        this.activeTunnels = activeTunnels

        val request = requestedConnection
        if (request != null) {
            if (activeTunnels.containsKey(request.profileId)) {
                requestedConnection = null
            } else if (!request.enabled && activeTunnels.isEmpty()) {
                requestedConnection = null
            } else if (request.enabled && activeTunnels.isEmpty() && !hadActiveTunnels) {
                requestedConnection = null
            }
            return
        }

        if (activeTunnels.isNotEmpty() && selectedProfileId !in activeTunnels.keys) {
            selectedProfileId = activeTunnels.keys.first()
        }
    }

    fun selectProfile(profileId: String) {
        if (headers.containsKey(profileId)) {
            selectedProfileId = profileId
        }
    }

    fun requestProfileToggle(profileId: String, enabled: Boolean) {
        requestedConnection = RequestedConnection(profileId, enabled)
        selectProfile(profileId)
    }

    fun clearRequestedProfileToggle(profileId: String? = null) {
        if (profileId == null || requestedConnection?.profileId == profileId) {
            requestedConnection = null
        }
    }

    fun isProfileEnabled(profileId: String): Boolean {
        return activeTunnels[profileId]?.isEnabled ?: false
    }

    fun profileStatus(profileId: String): AppProfileStatus {
        return activeTunnels[profileId]?.status
            ?: requestedConnection?.statusFor(profileId)
            ?: AppProfileStatus.disconnected
    }

    fun handleEvent(event: Event) {
        when (event) {
            is ProfileEventRefresh -> {
                updateProfiles(event.headers)
            }
            is TunnelEventRefresh -> {
                updateActiveTunnels(event.active)
            }
            is ProfileEventSave -> {
                selectProfile(event.profile.id)
            }
            else -> {
                // Other events
            }
        }
    }
}

private data class RequestedConnection(
    val profileId: String,
    val enabled: Boolean
) {
    fun statusFor(candidateId: String): AppProfileStatus? {
        if (candidateId != profileId) {
            return null
        }
        return if (enabled) {
            AppProfileStatus.connecting
        } else {
            AppProfileStatus.disconnecting
        }
    }
}
