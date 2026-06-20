// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.app

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.algoritmico.passepartout.models.AppProfileHeader
import com.algoritmico.passepartout.models.AppProfileStatus
import com.algoritmico.passepartout.models.ProfileTransfer
import com.algoritmico.passepartout.ui.extensions.statusText
import com.algoritmico.passepartout.ui.extensions.transferText
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.ThemeCrossfade
import com.algoritmico.passepartout.ui.theme.animateThemeColorAsState

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ProfileRow(
    header: AppProfileHeader,
    isEnabled: Boolean,
    status: AppProfileStatus,
    transfer: ProfileTransfer?,
    lastErrorCode: String?,
    isSelected: Boolean,
    onProfileSelected: (String) -> Unit,
    onProfileToggle: (String, Boolean) -> Unit,
    onProfileContextualAction: (String) -> Unit
) {
    val theme = LocalTheme.current
    val showsTransfer = lastErrorCode == null && status == AppProfileStatus.connected && transfer != null
    val statusDescription = lastErrorCode ?: status.statusText()
    val transferDescription = transfer?.transferText()
    val statusDescriptionColor = if (lastErrorCode != null) {
        theme.colors.error
    } else {
        statusColor(status)
    }
    val animatedStatusDescriptionColor by animateThemeColorAsState(
        targetValue = statusDescriptionColor,
        label = "Profile status color"
    )
    val containerColor = if (isSelected) {
        MaterialTheme.colorScheme.secondaryContainer
    } else {
        MaterialTheme.colorScheme.surface
    }

    OutlinedCard(
        modifier = Modifier
            .fillMaxWidth()
            .combinedClickable(
                onClick = {
                    onProfileSelected(header.id)
                },
                onLongClick = {
                    onProfileContextualAction(header.id)
                }
            ),
        colors = CardDefaults.outlinedCardColors(
            containerColor = containerColor
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = theme.spacing.large, vertical = theme.spacing.large),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(theme.spacing.xSmall)
            ) {
                Text(
                    text = header.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = theme.weight.strong
                )
                ThemeCrossfade(
                    targetState = showsTransfer,
                    label = "Profile transfer visibility"
                ) { isShowingTransfer ->
                    Text(
                        text = if (isShowingTransfer) {
                            transferDescription ?: statusDescription
                        } else {
                            statusDescription
                        },
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = theme.weight.secondary,
                        color = animatedStatusDescriptionColor
                    )
                }
            }

            Spacer(modifier = Modifier.width(theme.spacing.large))

            Switch(
                checked = isEnabled,
                enabled = status.canToggle(),
                onCheckedChange = { isEnabled ->
                    onProfileSelected(header.id)
                    onProfileToggle(header.id, isEnabled)
                }
            )
        }
    }
}

@Composable
private fun statusColor(status: AppProfileStatus): Color {
    val theme = LocalTheme.current

    return when (status) {
        AppProfileStatus.connected -> theme.colors.active
        AppProfileStatus.connecting,
        AppProfileStatus.disconnecting -> theme.colors.pending
        AppProfileStatus.disconnected -> MaterialTheme.colorScheme.onSurfaceVariant.copy(
            alpha = theme.alpha.secondaryStatus
        )
    }
}

private fun AppProfileStatus.canToggle(): Boolean {
    return when (this) {
        AppProfileStatus.disconnecting -> false
        AppProfileStatus.connecting,
        AppProfileStatus.disconnected,
        AppProfileStatus.connected -> true
    }
}
