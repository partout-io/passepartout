// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.app

import androidx.compose.runtime.Stable
import com.algoritmico.passepartout.models.AppProfileHeader
import com.algoritmico.passepartout.models.AppProfileStatus
import com.algoritmico.passepartout.models.ProfileTransfer

@Stable
class ProfileContextualSelection(
    val profileIds: List<String> = emptyList(),
    private val onProfileSelected: (String) -> Unit = {},
    private val onProfileAction: (String) -> Unit = {}
) {
    val isActive: Boolean
        get() = profileIds.isNotEmpty()

    fun contains(profileId: String): Boolean {
        return profileId in profileIds
    }

    fun selectProfile(profileId: String) {
        onProfileSelected(profileId)
    }

    fun performProfileAction(profileId: String) {
        onProfileAction(profileId)
    }
}

@Stable
class ProfileContainerState(
    val headers: List<AppProfileHeader> = emptyList(),
    val contextualSelection: ProfileContextualSelection = ProfileContextualSelection(),
    private val enabledProfileIds: Set<String> = emptySet(),
    private val statuses: Map<String, AppProfileStatus> = emptyMap(),
    private val transfers: Map<String, ProfileTransfer> = emptyMap(),
    private val lastErrorCodes: Map<String, String> = emptyMap()
) {
    fun isProfileEnabled(profileId: String): Boolean {
        return profileId in enabledProfileIds
    }

    fun profileStatus(profileId: String): AppProfileStatus {
        return statuses[profileId] ?: AppProfileStatus.disconnected
    }

    fun profileTransfer(profileId: String): ProfileTransfer? {
        return transfers[profileId]
    }

    fun profileLastErrorCode(profileId: String): String? {
        return lastErrorCodes[profileId]
    }
}

@Stable
class ProfileContainerActions(
    val onProfileSelected: (String) -> Unit = {},
    val onProfileToggle: (String, Boolean) -> Unit = { _, _ -> },
    val onProfileContextualAction: (String) -> Unit = {}
)
