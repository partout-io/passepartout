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
import com.algoritmico.passepartout.abi.Event
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

@Composable
fun PassepartoutApp(
    events: Flow<Event>,
    onImportProfile: () -> Unit,
    onProfileToggle: suspend (String, Boolean) -> Boolean,
    onProfilesDelete: (Array<String>) -> Unit
) {
    val state = rememberPassepartoutAppState()
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(events) {
        events.collect(state::handleEvent)
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
                profiles = state.profiles,
                selectedProfileId = state.selectedProfileId,
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
