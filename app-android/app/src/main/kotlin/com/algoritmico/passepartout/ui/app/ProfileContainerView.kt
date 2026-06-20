// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
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
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.ThemeProgressView
import io.partout.models.TaggedProfile
import kotlinx.coroutines.launch

@Composable
fun ProfileContainerView(
    modifier: Modifier = Modifier,
    style: ProfileContainerStyle,
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

    ProfileStyleView(
        modifier = modifier,
        style = style,
        state = ProfileContainerState(
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
        actions = ProfileContainerActions(
            onProfileSelected = onProfileSelected,
            onProfileToggle = { profileId, enabled ->
                requestProfileConnection(profileId, enabled)
            },
            onProfileContextualAction = onProfileContextualAction
        )
    )
}

@Composable
private fun ProfileStyleView(
    modifier: Modifier,
    style: ProfileContainerStyle,
    state: ProfileContainerState,
    actions: ProfileContainerActions
) {
    when (style) {
        ProfileContainerStyle.list -> {
            ProfileListView(
                modifier = modifier.fillMaxSize(),
                state = state,
                actions = actions
            )
        }
        ProfileContainerStyle.grid -> {
            ProfileGridView(
                modifier = modifier.fillMaxSize(),
                state = state,
                actions = actions
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
            text = stringResource(R.string.views_app_folders_no_profiles),
            style = MaterialTheme.typography.headlineSmall
        )
        Spacer(modifier = Modifier.size(theme.spacing.medium))
        Text(
            text = stringResource(R.string.android_profiles_empty_message),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.size(theme.spacing.xLarge))
        TextButton(onClick = onImportProfile) {
            Text(stringResource(R.string.android_profiles_empty_import))
        }
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
