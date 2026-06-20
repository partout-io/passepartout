// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.unit.dp
import com.algoritmico.passepartout.business.extensions.blogURL
import com.algoritmico.passepartout.business.extensions.disclaimerURL
import com.algoritmico.passepartout.business.extensions.privacyPolicyURL
import com.algoritmico.passepartout.observables.LocalAppConfiguration
import com.algoritmico.passepartout.observables.LocalErrorHandler
import com.algoritmico.passepartout.observables.safeOpenUri
import com.algoritmico.passepartout.ui.theme.ThemeListSection
import com.algoritmico.passepartout.ui.theme.ThemeNavigatingButton

@Composable
fun LinksView(
    modifier: Modifier = Modifier
) {
    val appConfiguration = LocalAppConfiguration.current
    val constants = appConfiguration.constants
    val websites = constants.websites

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        item {
            ThemeListSection(header = "Support") {
                ExternalLinkRow(
                    title = "Open discussion",
                    url = constants.github.discussionsURL
                )
            }
        }
        item {
            ThemeListSection(header = "Web") {
                ExternalLinkRow(
                    title = "Home page",
                    url = websites.homeURL
                )
                ExternalLinkRow(
                    title = "Blog",
                    url = websites.blogURL
                )
            }
        }
        item {
            ThemeListSection {
                ExternalLinkRow(
                    title = "Disclaimer",
                    url = websites.disclaimerURL
                )
                ExternalLinkRow(
                    title = "Privacy policy",
                    url = websites.privacyPolicyURL
                )
            }
        }
    }
}

@Composable
private fun ExternalLinkRow(
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
