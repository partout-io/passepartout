// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.app

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.models.AppProfileStatus
import com.algoritmico.passepartout.models.ProfileTransfer
import com.algoritmico.passepartout.ui.theme.LocalTheme
import io.partout.models.PartoutErrorCode

@Composable
fun ProfileListView(
    modifier: Modifier,
    state: ProfileContainerState,
    actions: ProfileContainerActions = ProfileContainerActions()
) {
    val theme = LocalTheme.current

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(theme.spacing.large),
        verticalArrangement = Arrangement.spacedBy(theme.spacing.medium)
    ) {
        item {
            Text(
                text = stringResource(R.string.views_app_folders_default),
                style = MaterialTheme.typography.titleLarge
            )
        }
        items(
            items = state.headers,
            key = { it.id }
        ) { header ->
            ProfileRow(
                header = header,
                isEnabled = state.isProfileEnabled(header.id),
                status = state.profileStatus(header.id),
                transfer = state.profileTransfer(header.id),
                lastErrorCode = state.profileLastErrorCode(header.id),
                isSelected = state.contextualSelection.isActive && state.contextualSelection.contains(header.id),
                onProfileSelected = actions.onProfileSelected,
                onProfileToggle = actions.onProfileToggle,
                onProfileContextualAction = actions.onProfileContextualAction
            )
        }
    }
}

@Preview(widthDp = 393, heightDp = 852)
@Composable
private fun ProfileListViewPreview() {
    MaterialTheme {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            ProfileListView(
                modifier = Modifier,
                state = ProfileContainerState(
                    headers = PreviewProfileHeaders,
                    contextualSelection = ProfileContextualSelection(
                        profileIds = listOf("office")
                    ),
                    enabledProfileIds = setOf("home", "office"),
                    statuses = mapOf(
                        "home" to AppProfileStatus.connected,
                        "office" to AppProfileStatus.connecting,
                        "broken" to AppProfileStatus.disconnected
                    ),
                    transfers = mapOf(
                        "home" to ProfileTransfer(
                            received = 42_000_000L,
                            sent = 8_000_000L
                        )
                    ),
                    lastErrorCodes = mapOf(
                        "broken" to PartoutErrorCode.openVPNCompressionMismatch.value
                    )
                )
            )
        }
    }
}
