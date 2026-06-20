// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalUriHandler
import com.algoritmico.passepartout.observables.safeOpenUri
import com.algoritmico.passepartout.ui.LocalErrorHandler

@Composable
fun ThemeExternalLinkRow(
    title: String,
    url: String
) {
    val uriHandler = LocalUriHandler.current
    val errorHandler = LocalErrorHandler.current
    ThemeNavigatingButton(
        title = title,
        onClick = {
            uriHandler.safeOpenUri(url, errorHandler)
        }
    )
}
