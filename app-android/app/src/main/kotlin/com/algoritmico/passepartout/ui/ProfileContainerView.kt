// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.algoritmico.passepartout.abi.AppProfileHeader
import com.algoritmico.passepartout.abi.AppProfileStatus

@Composable
fun ProfileContainerView(
    modifier: Modifier = Modifier,
    profileObservable: ProfileObservable,
    selectedProfileId: String?,
    contextualProfileIds: List<String>,
    isProfileEnabled: (String) -> Boolean,
    profileStatus: (String) -> AppProfileStatus,
    onProfileSelected: (String) -> Unit,
    onProfileToggle: (String, Boolean) -> Unit,
    onProfileContextualAction: (String) -> Unit,
    onImportProfile: () -> Unit
) {
    val state by profileObservable.state.collectAsState()
    val headers = state.filteredHeaders

    if (headers.isEmpty()) {
        EmptyProfilesView(
            modifier = modifier,
            onImportProfile = onImportProfile
        )
        return
    }

    val selectedHeader = headers.firstOrNull { it.id == selectedProfileId } ?: headers.first()
    val isTablet = LocalConfiguration.current.screenWidthDp >= 840

    if (isTablet) {
        TabletProfilesView(
            modifier = modifier,
            headers = headers,
            selectedHeader = selectedHeader,
            contextualProfileIds = contextualProfileIds,
            isProfileEnabled = isProfileEnabled,
            profileStatus = profileStatus,
            onProfileSelected = onProfileSelected,
            onProfileToggle = onProfileToggle,
            onProfileContextualAction = onProfileContextualAction
        )
    } else {
        MobileProfilesView(
            modifier = modifier,
            headers = headers,
            selectedProfileId = selectedHeader.id,
            contextualProfileIds = contextualProfileIds,
            isProfileEnabled = isProfileEnabled,
            profileStatus = profileStatus,
            onProfileSelected = onProfileSelected,
            onProfileToggle = onProfileToggle,
            onProfileContextualAction = onProfileContextualAction
        )
    }
}

@Composable
private fun MobileProfilesView(
    modifier: Modifier,
    headers: List<AppProfileHeader>,
    selectedProfileId: String,
    contextualProfileIds: List<String>,
    isProfileEnabled: (String) -> Boolean,
    profileStatus: (String) -> AppProfileStatus,
    onProfileSelected: (String) -> Unit,
    onProfileToggle: (String, Boolean) -> Unit,
    onProfileContextualAction: (String) -> Unit
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text(
                text = "Profiles",
                style = MaterialTheme.typography.titleLarge
            )
        }
        items(
            items = headers,
            key = { it.id }
        ) { header ->
            ProfileRow(
                header = header,
                isEnabled = isProfileEnabled(header.id),
                status = profileStatus(header.id),
                isSelected = if (contextualProfileIds.isNotEmpty()) {
                    header.id in contextualProfileIds
                } else {
                    header.id == selectedProfileId
                },
                onProfileSelected = onProfileSelected,
                onProfileToggle = onProfileToggle,
                onProfileContextualAction = onProfileContextualAction
            )
        }
    }
}

@Composable
private fun TabletProfilesView(
    modifier: Modifier,
    headers: List<AppProfileHeader>,
    selectedHeader: AppProfileHeader,
    contextualProfileIds: List<String>,
    isProfileEnabled: (String) -> Boolean,
    profileStatus: (String) -> AppProfileStatus,
    onProfileSelected: (String) -> Unit,
    onProfileToggle: (String, Boolean) -> Unit,
    onProfileContextualAction: (String) -> Unit
) {
    Row(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        ElevatedCard(
            modifier = Modifier
                .weight(0.42f)
                .fillMaxHeight()
        ) {
            LazyColumn(
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item {
                    Text(
                        text = "Profiles",
                        style = MaterialTheme.typography.titleLarge
                    )
                }
                items(
                    items = headers,
                    key = { it.id }
                ) { header ->
                    ProfileRow(
                        header = header,
                        isEnabled = isProfileEnabled(header.id),
                        status = profileStatus(header.id),
                        isSelected = if (contextualProfileIds.isNotEmpty()) {
                            header.id in contextualProfileIds
                        } else {
                            header.id == selectedHeader.id
                        },
                        onProfileSelected = onProfileSelected,
                        onProfileToggle = onProfileToggle,
                        onProfileContextualAction = onProfileContextualAction
                    )
                }
            }
        }

        ProfileDetailCard(
            modifier = Modifier
                .weight(0.58f)
                .fillMaxHeight(),
            header = selectedHeader,
            isEnabled = isProfileEnabled(selectedHeader.id),
            status = profileStatus(selectedHeader.id),
            onProfileToggle = onProfileToggle
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun ProfileRow(
    header: AppProfileHeader,
    isEnabled: Boolean,
    status: AppProfileStatus,
    isSelected: Boolean,
    onProfileSelected: (String) -> Unit,
    onProfileToggle: (String, Boolean) -> Unit,
    onProfileContextualAction: (String) -> Unit
) {
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
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = header.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = header.moduleSummary(),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = status.statusText(),
                    style = MaterialTheme.typography.bodySmall,
                    color = statusColor(status)
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

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
private fun ProfileDetailCard(
    modifier: Modifier,
    header: AppProfileHeader,
    isEnabled: Boolean,
    status: AppProfileStatus,
    onProfileToggle: (String, Boolean) -> Unit
) {
    ElevatedCard(
        modifier = modifier
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            Column(
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(
                    text = header.name,
                    style = MaterialTheme.typography.headlineMedium
                )
                Text(
                    text = status.statusText(),
                    style = MaterialTheme.typography.titleMedium,
                    color = statusColor(status)
                )
            }

            DetailLine(
                title = "Primary module",
                value = header.moduleSummary()
            )
            DetailLine(
                title = "Fingerprint",
                value = header.fingerprint
            )
            DetailLine(
                title = "Profile ID",
                value = header.id
            )

            Spacer(modifier = Modifier.weight(1f))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = "Connection",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Text(
                        text = "Turn this profile on or off.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Switch(
                    checked = isEnabled,
                    enabled = status.canToggle(),
                    onCheckedChange = { isEnabled ->
                        onProfileToggle(header.id, isEnabled)
                    }
                )
            }
        }
    }
}

@Composable
private fun DetailLine(
    title: String,
    value: String
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyLarge
        )
    }
}

@Composable
private fun EmptyProfilesView(
    modifier: Modifier,
    onImportProfile: () -> Unit
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "No profiles imported yet.",
            style = MaterialTheme.typography.headlineSmall
        )
        Spacer(modifier = Modifier.size(12.dp))
        Text(
            text = "Import a profile file to get started.",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.size(20.dp))
        TextButton(onClick = onImportProfile) {
            Text("Import profile")
        }
    }
}

@Composable
private fun statusColor(status: AppProfileStatus): Color = when (status) {
    AppProfileStatus.connected -> MaterialTheme.colorScheme.primary
    AppProfileStatus.connecting,
    AppProfileStatus.disconnecting -> MaterialTheme.colorScheme.secondary

    AppProfileStatus.disconnected -> MaterialTheme.colorScheme.onSurfaceVariant
}

private fun AppProfileHeader.moduleSummary(): String {
    return primaryModuleType?.value
        ?: moduleTypes.firstOrNull()?.value
        ?: "Profile"
}

private fun AppProfileStatus.statusText(): String {
    return when (this) {
        AppProfileStatus.disconnected -> "Disconnected"
        AppProfileStatus.connecting -> "Connecting"
        AppProfileStatus.connected -> "Connected"
        AppProfileStatus.disconnecting -> "Disconnecting"
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
