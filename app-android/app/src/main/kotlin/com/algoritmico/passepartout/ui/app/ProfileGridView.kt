// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.app

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
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
fun ProfileGridView(
    modifier: Modifier,
    state: ProfileContainerState,
    actions: ProfileContainerActions = ProfileContainerActions()
) {
    val theme = LocalTheme.current

    LazyVerticalGrid(
        columns = GridCells.Adaptive(minSize = theme.grid.minCellWidth),
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(theme.spacing.large),
        horizontalArrangement = Arrangement.spacedBy(theme.spacing.medium),
        verticalArrangement = Arrangement.spacedBy(theme.spacing.medium)
    ) {
        item(
            span = {
                GridItemSpan(maxLineSpan)
            }
        ) {
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

@Preview(widthDp = 840, heightDp = 852)
@Composable
private fun ProfileGridViewPreview() {
    MaterialTheme {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            ProfileGridView(
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
                        "broken" to PartoutErrorCode.timeout.value
                    )
                )
            )
        }
    }
}
