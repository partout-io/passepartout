// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalUriHandler
import com.algoritmico.passepartout.extensions.versionString
import com.algoritmico.passepartout.observables.LocalVersionObservable

@Composable
fun VersionUpdateLink() {
    val versionObservable = LocalVersionObservable.current
    val state by versionObservable.state.collectAsState()
    val latestRelease = state.latestRelease ?: return
    val uriHandler = LocalUriHandler.current

    SettingsLinkRow(
        title = "Update to ${latestRelease.version.versionString}",
        onClick = {
            uriHandler.openUri(latestRelease.url)
        }
    )
}
