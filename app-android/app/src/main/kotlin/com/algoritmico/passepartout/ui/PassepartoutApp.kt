// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.launch

@Composable
fun PassepartoutApp(
    profileObservable: ProfileObservable,
    onImportProfile: () -> Unit,
    onProfileToggle: suspend (String, Boolean) -> Boolean,
    onProfilesDelete: (Array<String>) -> Unit
) {
    val state = rememberPassepartoutAppState()
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(profileObservable) {
        profileObservable.state.collect { profileState ->
            state.updateProfiles(profileState.filteredHeaders.associateBy { it.id })
        }
    }

    LaunchedEffect(profileObservable) {
        profileObservable.events.collect(state::handleEvent)
    }

    val colorScheme = if (isSystemInDarkTheme()) {
        darkColorScheme()
    } else {
        lightColorScheme()
    }

    MaterialTheme(colorScheme = colorScheme) {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            AppCoordinator(
                title = "Passepartout",
                profileObservable = profileObservable,
                selectedProfileId = state.selectedProfileId,
                isProfileEnabled = state::isProfileEnabled,
                profileStatus = state::profileStatus,
                onProfileSelected = state::selectProfile,
                onProfileToggle = { profileId, enabled ->
                    state.requestProfileToggle(profileId, enabled)
                    coroutineScope.launch {
                        val didStart = try {
                            onProfileToggle(profileId, enabled)
                        } catch (e: CancellationException) {
                            throw e
                        } catch (_: Exception) {
                            false
                        }
                        if (!didStart) {
                            state.clearRequestedProfileToggle(profileId)
                        }
                    }
                },
                onProfilesDelete = onProfilesDelete,
                onImportProfile = onImportProfile
            )
        }
    }
}
