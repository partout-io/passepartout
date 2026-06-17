// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.app

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
import com.algoritmico.passepartout.injection.throwIfCancellation
import com.algoritmico.passepartout.models.AppProfileHeader
import com.algoritmico.passepartout.models.AppProfileStatus
import com.algoritmico.passepartout.models.AppTunnelInfo
import com.algoritmico.passepartout.models.ProfileTransfer
import com.algoritmico.passepartout.observables.ErrorHandler
import com.algoritmico.passepartout.observables.LocalErrorHandler
import com.algoritmico.passepartout.observables.ProfileObservable
import com.algoritmico.passepartout.observables.TunnelObservable
import com.algoritmico.passepartout.ui.alerts.InteractiveOpenVPNView
import com.algoritmico.passepartout.ui.alerts.VpnPermissionDeniedAlert
import com.algoritmico.passepartout.ui.models.statusText
import com.algoritmico.passepartout.ui.models.transferText
import io.partout.models.TaggedProfile
import kotlinx.coroutines.launch

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
    val errorHandler = LocalErrorHandler.current

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

    fun requestProfileConnection(
        profileId: String,
        enabled: Boolean,
        profile: TaggedProfile? = null,
        force: Boolean = false
    ) {
        val request = RequestedConnection(profileId, enabled)
        requestedConnection = request
        selectProfile(profileId)
        coroutineScope.launch {
            val didStart = runCatching {
                if (enabled) {
                    val connectionProfile = profile ?: profileObservable.profile(profileId)
                    if (connectionProfile == null) {
                        false
                    } else {
                        tunnelObservable.connect(connectionProfile, force = force)
                        true
                    }
                } else {
                    tunnelObservable.disconnect(profileId)
                    true
                }
            }.getOrElse {
                it.throwIfCancellation()
                when (it) {
                    is TunnelObservable.InteractiveException -> {
                        interactiveProfile = it.profile
                        false
                    }
                    else -> {
                        errorHandler.report(it)
                        false
                    }
                }
            }
            if (didStart && profile != null) {
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
                openVpnSettings(context, errorHandler)
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
                requestProfileConnection(
                    profileId = it.id,
                    enabled = true,
                    profile = it,
                    force = true
                )
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

    MobileProfilesView(
        modifier = modifier,
        headers = headers,
        contextualProfileIds = contextualProfileIds,
        isProfileEnabled = ::isProfileEnabled,
        profileStatus = ::profileStatus,
        profileTransfer = ::profileTransfer,
        profileLastErrorCode = ::profileLastErrorCode,
        onProfileSelected = onProfileSelected,
        onProfileToggle = { profileId, enabled ->
            requestProfileConnection(profileId, enabled)
        },
        onProfileContextualAction = onProfileContextualAction
    )
}

@Composable
private fun MobileProfilesView(
    modifier: Modifier,
    headers: List<AppProfileHeader>,
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

private fun openVpnSettings(context: Context, errorHandler: ErrorHandler) {
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
        }.onFailure {
            errorHandler.report(it)
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

private fun AppProfileStatus.canToggle(): Boolean {
    return when (this) {
        AppProfileStatus.disconnecting -> false
        AppProfileStatus.connecting,
        AppProfileStatus.disconnected,
        AppProfileStatus.connected -> true
    }
}

private val ProfileStatusActiveColor = Color(0xFF00AA00)
private val ProfileStatusPendingColor = Color(0xFFFF9800)
private val ProfileStatusErrorColor = Color(0xFFD32F2F)
