// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.algoritmico.passepartout.models.AppProfileHeader
import com.algoritmico.passepartout.models.AppProfileStatus
import com.algoritmico.passepartout.models.AppTunnelInfo
import com.algoritmico.passepartout.models.ProfileEventSave
import com.algoritmico.passepartout.models.ProfileTransfer
import com.algoritmico.passepartout.observables.ProfileObservable
import com.algoritmico.passepartout.observables.TunnelObservable
import io.partout.models.TaggedProfile
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.launch
import java.util.Locale

@Composable
fun ProfileContainerView(
    modifier: Modifier = Modifier,
    profileObservable: ProfileObservable,
    tunnelObservable: TunnelObservable,
    contextualProfileIds: List<String>,
    onContextualProfileSelected: (String) -> Unit,
    onContextualProfileAction: (String) -> Unit,
    onImportProfile: () -> Unit
) {
    val profileState by profileObservable.state.collectAsState()
    val tunnelState by tunnelObservable.state.collectAsState()
    val coroutineScope = rememberCoroutineScope()
    val context = LocalContext.current
    val headers = profileState.filteredHeaders
    val profileIds = headers.map { it.id }
    val activeProfiles = tunnelState.activeProfiles
    var selectedProfileId by rememberSaveable {
        mutableStateOf<String?>(null)
    }
    var requestedConnection by remember {
        mutableStateOf<RequestedConnection?>(null)
    }
    var interactiveProfile by remember {
        mutableStateOf<TaggedProfile?>(null)
    }
    var previousActiveProfiles by remember {
        mutableStateOf<Map<String, AppTunnelInfo>>(emptyMap())
    }

    fun selectProfile(profileId: String) {
        if (profileId in profileIds) {
            selectedProfileId = profileId
        }
    }

    fun isProfileEnabled(profileId: String): Boolean {
        return activeProfiles[profileId]?.isEnabled ?: false
    }

    fun profileStatus(profileId: String): AppProfileStatus {
        return activeProfiles[profileId]?.status
            ?: requestedConnection?.statusFor(profileId)
            ?: AppProfileStatus.disconnected
    }

    fun profileTransfer(profileId: String): ProfileTransfer? {
        return activeProfiles[profileId]?.transfer
    }

    fun profileLastErrorCode(profileId: String): String? {
        return activeProfiles[profileId]?.lastErrorCode
    }

    fun requestProfileToggle(profileId: String, enabled: Boolean) {
        val request = RequestedConnection(profileId, enabled)
        requestedConnection = request
        selectProfile(profileId)
        coroutineScope.launch {
            val didStart = try {
                toggleProfile(
                    profileObservable,
                    tunnelObservable,
                    profileId,
                    enabled
                )
            } catch (e: CancellationException) {
                throw e
            } catch (e: TunnelObservable.InteractiveException) {
                interactiveProfile = e.profile
                false
            } catch (_: Exception) {
                false
            }
            if (!didStart && requestedConnection == request) {
                requestedConnection = null
            }
        }
    }

    fun requestProfileConnection(profile: TaggedProfile, force: Boolean = false) {
        val request = RequestedConnection(profile.id, enabled = true)
        requestedConnection = request
        selectProfile(profile.id)
        coroutineScope.launch {
            val didStart = try {
                tunnelObservable.connect(profile, force = force)
                true
            } catch (e: CancellationException) {
                throw e
            } catch (e: TunnelObservable.InteractiveException) {
                interactiveProfile = e.profile
                false
            } catch (_: Exception) {
                false
            }
            if (didStart) {
                interactiveProfile = null
            }
            if (!didStart && requestedConnection == request) {
                requestedConnection = null
            }
        }
    }

    LaunchedEffect(profileIds) {
        if (selectedProfileId !in profileIds) {
            selectedProfileId = profileIds.firstOrNull()
        }
    }

    LaunchedEffect(profileObservable) {
        profileObservable.events.collect { event ->
            if (event is ProfileEventSave) {
                selectedProfileId = event.profile.id
            }
        }
    }

    LaunchedEffect(activeProfiles) {
        val hadActiveProfiles = previousActiveProfiles.isNotEmpty()
        val request = requestedConnection
        if (request != null) {
            if (activeProfiles.containsKey(request.profileId)) {
                requestedConnection = null
            } else if (!request.enabled && activeProfiles.isEmpty()) {
                requestedConnection = null
            } else if (request.enabled && activeProfiles.isEmpty() && !hadActiveProfiles) {
                requestedConnection = null
            }
        } else if (activeProfiles.isNotEmpty() && selectedProfileId !in activeProfiles.keys) {
            selectedProfileId = activeProfiles.keys.first()
        }
        previousActiveProfiles = activeProfiles
    }

    LaunchedEffect(tunnelState.isVpnPermissionDenied) {
        if (tunnelState.isVpnPermissionDenied) {
            requestedConnection = null
        }
    }

    val onProfileSelected: (String) -> Unit = { profileId ->
        if (contextualProfileIds.isNotEmpty()) {
            onContextualProfileSelected(profileId)
        } else {
            selectProfile(profileId)
        }
    }
    val onProfileContextualAction: (String) -> Unit = { profileId ->
        if (profileId !in contextualProfileIds) {
            onContextualProfileAction(profileId)
        }
        selectProfile(profileId)
    }

    if (tunnelState.isVpnPermissionDenied) {
        VpnPermissionDeniedAlert(
            onDismiss = {
                tunnelObservable.clearVpnPermissionDenied()
            },
            onOpenSettings = {
                tunnelObservable.clearVpnPermissionDenied()
                openVpnSettings(context)
            }
        )
    }

    interactiveProfile?.let { profile ->
        InteractiveOpenVPNView(
            profile = profile,
            onDismiss = {
                interactiveProfile = null
            },
            onConnect = {
                interactiveProfile = null
                requestProfileConnection(it, force = true)
            }
        )
    }

    if (headers.isEmpty()) {
        if (profileState.isReady) {
            EmptyProfilesView(
                modifier = modifier,
                onImportProfile = onImportProfile
            )
        } else {
            LoadingProfilesView(modifier = modifier)
        }
        return
    }

    val selectedHeader = headers.firstOrNull { it.id == selectedProfileId } ?: headers.first()
    MobileProfilesView(
        modifier = modifier,
        headers = headers,
        selectedProfileId = selectedHeader.id,
        contextualProfileIds = contextualProfileIds,
        isProfileEnabled = ::isProfileEnabled,
        profileStatus = ::profileStatus,
        profileTransfer = ::profileTransfer,
        profileLastErrorCode = ::profileLastErrorCode,
        onProfileSelected = onProfileSelected,
        onProfileToggle = ::requestProfileToggle,
        onProfileContextualAction = onProfileContextualAction
    )
}

@Composable
private fun VpnPermissionDeniedAlert(
    onDismiss: () -> Unit,
    onOpenSettings: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text("VPN permission required")
        },
        text = {
            Text("Passepartout needs VPN permission to start a connection.")
        },
        confirmButton = {
            TextButton(onClick = onOpenSettings) {
                Text("Open VPN settings")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("OK")
            }
        }
    )
}

@Composable
private fun MobileProfilesView(
    modifier: Modifier,
    headers: List<AppProfileHeader>,
    selectedProfileId: String,
    contextualProfileIds: List<String>,
    isProfileEnabled: (String) -> Boolean,
    profileStatus: (String) -> AppProfileStatus,
    profileTransfer: (String) -> ProfileTransfer?,
    profileLastErrorCode: (String) -> String?,
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
                text = "My Profiles",
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
                transfer = profileTransfer(header.id),
                lastErrorCode = profileLastErrorCode(header.id),
                isSelected = contextualProfileIds.isNotEmpty() && header.id in contextualProfileIds,
                onProfileSelected = onProfileSelected,
                onProfileToggle = onProfileToggle,
                onProfileContextualAction = onProfileContextualAction
            )
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun ProfileRow(
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
    val showsTransfer = lastErrorCode == null && status == AppProfileStatus.connected && transfer != null
    val statusDescription = lastErrorCode ?: status.statusText()
    val transferDescription = transfer?.transferText()
    val statusDescriptionColor = if (lastErrorCode != null) {
        ProfileStatusErrorColor
    } else {
        statusColor(status)
    }
    val animatedStatusDescriptionColor by animateColorAsState(
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
                .padding(horizontal = 16.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = header.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Crossfade(
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
                        fontWeight = FontWeight.Light,
                        color = animatedStatusDescriptionColor
                    )
                }
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
private fun LoadingProfilesView(
    modifier: Modifier
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator()
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
    AppProfileStatus.connected -> ProfileStatusActiveColor
    AppProfileStatus.connecting,
    AppProfileStatus.disconnecting -> ProfileStatusPendingColor

    AppProfileStatus.disconnected -> MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.72f)
}

private fun AppProfileStatus.statusText(): String {
    return when (this) {
        AppProfileStatus.disconnected -> "Inactive"
        AppProfileStatus.connecting -> "Activating"
        AppProfileStatus.connected -> "Active"
        AppProfileStatus.disconnecting -> "Deactivating"
    }
}

private fun ProfileTransfer.transferText(): String {
    return "↓${received.toLong().formatDataUnit()} ↑${sent.toLong().formatDataUnit()}"
}

private fun Long.formatDataUnit(): String {
    val value = coerceAtLeast(0L)
    if (value == 0L) {
        return "0B"
    }
    if (value < KILOBYTE) {
        return "${value}B"
    }
    return when {
        value >= GIGABYTE / 10L -> value.formatDecimalDataUnit(GIGABYTE, "GB")
        value >= MEGABYTE / 10L -> value.formatDecimalDataUnit(MEGABYTE, "MB")
        else -> "${value / KILOBYTE}kB"
    }
}

private fun Long.formatDecimalDataUnit(unitSize: Long, unit: String): String {
    val count = toDouble() / unitSize.toDouble()
    return String.format(Locale.US, "%.2f%s", count, unit)
}

private fun AppProfileStatus.canToggle(): Boolean {
    return when (this) {
        AppProfileStatus.disconnecting -> false

        AppProfileStatus.connecting,
        AppProfileStatus.disconnected,
        AppProfileStatus.connected -> true
    }
}

private fun openVpnSettings(context: Context) {
    val vpnSettingsIntent = Intent(Settings.ACTION_VPN_SETTINGS)
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    val appSettingsIntent = Intent(
        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
        Uri.fromParts("package", context.packageName, null)
    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

    runCatching {
        context.startActivity(vpnSettingsIntent)
    }.onFailure {
        runCatching {
            context.startActivity(appSettingsIntent)
        }
    }
}

private suspend fun toggleProfile(
    profileObservable: ProfileObservable,
    tunnelObservable: TunnelObservable,
    profileId: String,
    enabled: Boolean
): Boolean {
    if (!enabled) {
        tunnelObservable.disconnect(profileId)
        return true
    }

    val profile = profileObservable.profile(profileId) ?: return false
    tunnelObservable.connect(profile)
    return true
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

private const val KILOBYTE = 1024L
private const val MEGABYTE = KILOBYTE * 1024L
private const val GIGABYTE = MEGABYTE * 1024L

private val ProfileStatusActiveColor = Color(0xFF00AA00)
private val ProfileStatusPendingColor = Color(0xFFFF9800)
private val ProfileStatusErrorColor = Color(0xFFD32F2F)
