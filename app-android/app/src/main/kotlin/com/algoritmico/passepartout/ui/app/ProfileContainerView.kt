// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
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
import androidx.compose.ui.tooling.preview.Preview
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.models.AppProfileHeader
import com.algoritmico.passepartout.models.AppProfileStatus
import com.algoritmico.passepartout.models.AppTunnelInfo
import com.algoritmico.passepartout.models.ProfileTransfer
import com.algoritmico.passepartout.observables.ErrorHandler
import com.algoritmico.passepartout.ui.LocalErrorHandler
import com.algoritmico.passepartout.ui.LocalProfileObservable
import com.algoritmico.passepartout.ui.LocalTunnelObservable
import com.algoritmico.passepartout.observables.TunnelObservableException
import com.algoritmico.passepartout.ui.alerts.InteractiveView
import com.algoritmico.passepartout.ui.alerts.VpnPermissionDeniedAlert
import com.algoritmico.passepartout.ui.extensions.statusText
import com.algoritmico.passepartout.ui.extensions.transferText
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.ThemeCrossfade
import com.algoritmico.passepartout.ui.theme.ThemeProgressView
import com.algoritmico.passepartout.ui.theme.animateThemeColorAsState
import io.partout.models.ModuleType
import io.partout.models.TaggedProfile
import kotlinx.coroutines.launch

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
class ProfileListState(
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
class ProfileListActions(
    val onProfileSelected: (String) -> Unit = {},
    val onProfileToggle: (String, Boolean) -> Unit = { _, _ -> },
    val onProfileContextualAction: (String) -> Unit = {}
)

@Composable
fun ProfileContainerView(
    modifier: Modifier = Modifier,
    contextualSelection: ProfileContextualSelection = ProfileContextualSelection(),
    onImportProfile: () -> Unit
) {
    val profileObservable = LocalProfileObservable.current
    val tunnelObservable = LocalTunnelObservable.current
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
            val didStart = runCatchingNonFatal {
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
                when (it) {
                    is TunnelObservableException.Interactive -> {
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
        if (contextualSelection.isActive) {
            contextualSelection.selectProfile(profileId)
        } else {
            selectProfile(profileId)
        }
    }
    val onProfileContextualAction: (String) -> Unit = { profileId ->
        if (!contextualSelection.contains(profileId)) {
            contextualSelection.performProfileAction(profileId)
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
        InteractiveView(
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
        state = ProfileListState(
            headers = headers,
            contextualSelection = contextualSelection,
            enabledProfileIds = headers
                .map { it.id }
                .filter(::isProfileEnabled)
                .toSet(),
            statuses = headers.associate {
                it.id to profileStatus(it.id)
            },
            transfers = headers.mapNotNull {
                profileTransfer(it.id)?.let { transfer ->
                    it.id to transfer
                }
            }.toMap(),
            lastErrorCodes = headers.mapNotNull {
                profileLastErrorCode(it.id)?.let { lastErrorCode ->
                    it.id to lastErrorCode
                }
            }.toMap()
        ),
        actions = ProfileListActions(
            onProfileSelected = onProfileSelected,
            onProfileToggle = { profileId, enabled ->
                requestProfileConnection(profileId, enabled)
            },
            onProfileContextualAction = onProfileContextualAction
        )
    )
}

@Composable
private fun MobileProfilesView(
    modifier: Modifier,
    state: ProfileListState,
    actions: ProfileListActions = ProfileListActions()
) {
    val theme = LocalTheme.current

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(theme.spacing.large),
        verticalArrangement = Arrangement.spacedBy(theme.spacing.medium)
    ) {
        item {
            Text(
                text = "My Profiles",
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
private fun LoadingProfilesView(
    modifier: Modifier
) {
    ThemeProgressView(modifier = modifier)
}

@Composable
private fun EmptyProfilesView(
    modifier: Modifier,
    onImportProfile: () -> Unit
) {
    val theme = LocalTheme.current

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(theme.spacing.xxLarge),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "No profiles imported yet.",
            style = MaterialTheme.typography.headlineSmall
        )
        Spacer(modifier = Modifier.size(theme.spacing.medium))
        Text(
            text = "Import a profile file to get started.",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.size(theme.spacing.xLarge))
        TextButton(onClick = onImportProfile) {
            Text("Import profile")
        }
    }
}

@Preview(widthDp = 393, heightDp = 852)
@Composable
private fun MobileProfilesViewPreview() {
    MaterialTheme {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            MobileProfilesView(
                modifier = Modifier,
                state = ProfileListState(
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
                        "broken" to "TLS handshake failed"
                    )
                )
            )
        }
    }
}

private val PreviewProfileHeaders = listOf(
    previewProfileHeader(
        id = "home",
        name = "Home VPN",
        moduleType = ModuleType.WireGuard
    ),
    previewProfileHeader(
        id = "office",
        name = "Office",
        moduleType = ModuleType.OpenVPN
    ),
    previewProfileHeader(
        id = "broken",
        name = "Staging",
        moduleType = ModuleType.OpenVPN
    )
)

private fun previewProfileHeader(
    id: String,
    name: String,
    moduleType: ModuleType
): AppProfileHeader {
    return AppProfileHeader(
        id = id,
        name = name,
        moduleTypes = listOf(moduleType),
        secondaryModuleTypes = emptyList(),
        fingerprint = id,
        sharingFlags = emptyList(),
        requiredFeatures = emptyList(),
        primaryModuleType = moduleType
    )
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

private fun openVpnSettings(context: Context, errorHandler: ErrorHandler) {
    val vpnSettingsIntent = Intent(Settings.ACTION_VPN_SETTINGS)
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    val appSettingsIntent = Intent(
        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
        Uri.fromParts("package", context.packageName, null)
    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

    runCatchingNonFatal {
        context.startActivity(vpnSettingsIntent)
    }.onFailure {
        runCatchingNonFatal {
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
