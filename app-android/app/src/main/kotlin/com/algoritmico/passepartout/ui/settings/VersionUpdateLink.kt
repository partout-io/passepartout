// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalUriHandler
import com.algoritmico.passepartout.business.extensions.versionString
import com.algoritmico.passepartout.observables.LocalErrorHandler
import com.algoritmico.passepartout.observables.LocalVersionObservable
import com.algoritmico.passepartout.observables.safeOpenUri
import com.algoritmico.passepartout.ui.theme.ThemeNavigatingButton

@Composable
fun VersionUpdateLink() {
    val versionObservable = LocalVersionObservable.current
    val state by versionObservable.state.collectAsState()
    val latestRelease = state.latestRelease ?: return
    val uriHandler = LocalUriHandler.current
    val errorHandler = LocalErrorHandler.current

    ThemeNavigatingButton(
        title = "Update to ${latestRelease.version.versionString}",
        onClick = {
            uriHandler.safeOpenUri(latestRelease.url, errorHandler)
        }
    )
}
