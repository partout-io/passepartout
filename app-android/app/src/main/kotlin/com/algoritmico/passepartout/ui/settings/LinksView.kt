// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.algoritmico.passepartout.business.extensions.blogURL
import com.algoritmico.passepartout.business.extensions.disclaimerURL
import com.algoritmico.passepartout.business.extensions.privacyPolicyURL
import com.algoritmico.passepartout.ui.LocalAppConfiguration
import com.algoritmico.passepartout.ui.theme.ThemeExternalLinkRow
import com.algoritmico.passepartout.ui.theme.ThemeList
import com.algoritmico.passepartout.ui.theme.themeListSection

@Composable
fun LinksView(
    modifier: Modifier = Modifier
) {
    val appConfiguration = LocalAppConfiguration.current
    val constants = appConfiguration.constants
    val websites = constants.websites

    ThemeList(modifier = modifier) {
        themeListSection(header = "Support") {
            item {
                ThemeExternalLinkRow(
                    title = "Open discussion",
                    url = constants.github.discussionsURL
                )
            }
        }
        themeListSection(header = "Web") {
            item {
                ThemeExternalLinkRow(
                    title = "Home page",
                    url = websites.homeURL
                )
            }
            item {
                ThemeExternalLinkRow(
                    title = "Blog",
                    url = websites.blogURL
                )
            }
        }
        themeListSection {
            item {
                ThemeExternalLinkRow(
                    title = "Disclaimer",
                    url = websites.disclaimerURL
                )
            }
            item {
                ThemeExternalLinkRow(
                    title = "Privacy policy",
                    url = websites.privacyPolicyURL
                )
            }
        }
    }
}
