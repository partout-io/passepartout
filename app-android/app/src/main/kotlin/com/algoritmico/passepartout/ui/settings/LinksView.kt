// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.algoritmico.passepartout.extensions.blogURL
import com.algoritmico.passepartout.extensions.disclaimerURL
import com.algoritmico.passepartout.extensions.privacyPolicyURL
import com.algoritmico.passepartout.ui.observables.LocalAppConfiguration
import com.algoritmico.passepartout.ui.observables.LocalErrorHandler
import com.algoritmico.passepartout.ui.observables.safeOpenUri

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
            LinksSection(header = "Support") {
                ExternalLinkRow(
                    title = "Open discussion",
                    url = constants.github.discussionsURL
                )
            }
        }
        item {
            LinksSection(header = "Web") {
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
            LinksSection {
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
private fun LinksSection(
    header: String? = null,
    content: @Composable () -> Unit
) {
    Column {
        if (header != null) {
            Text(
                text = header,
                modifier = Modifier.padding(
                    start = 16.dp,
                    top = 20.dp,
                    end = 16.dp,
                    bottom = 8.dp
                ),
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.SemiBold
            )
        }
        content()
        HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
    }
}

@Composable
private fun ExternalLinkRow(
    title: String,
    url: String
) {
    val uriHandler = LocalUriHandler.current
    val errorHandler = LocalErrorHandler.current
    ListItem(
        modifier = Modifier
            .fillMaxWidth()
            .clickable {
                uriHandler.safeOpenUri(url, errorHandler)
            },
        headlineContent = {
            Text(title)
        }
    )
}
