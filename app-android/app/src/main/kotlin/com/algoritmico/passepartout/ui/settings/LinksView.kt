// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
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
    val supportHeader = stringResource(R.string.views_settings_links_sections_support)
    val webHeader = stringResource(R.string.views_settings_links_sections_web)

    ThemeList(modifier = modifier) {
        themeListSection(header = supportHeader) {
            item {
                ThemeExternalLinkRow(
                    title = stringResource(R.string.views_settings_links_rows_open_discussion),
                    url = constants.github.discussionsURL
                )
            }
        }
        themeListSection(header = webHeader) {
            item {
                ThemeExternalLinkRow(
                    title = stringResource(R.string.views_settings_links_rows_home_page),
                    url = websites.homeURL
                )
            }
            item {
                ThemeExternalLinkRow(
                    title = stringResource(R.string.views_settings_links_rows_blog),
                    url = websites.blogURL
                )
            }
        }
        themeListSection {
            item {
                ThemeExternalLinkRow(
                    title = stringResource(R.string.views_settings_links_rows_disclaimer),
                    url = websites.disclaimerURL
                )
            }
            item {
                ThemeExternalLinkRow(
                    title = stringResource(R.string.views_settings_links_rows_privacy_policy),
                    url = websites.privacyPolicyURL
                )
            }
        }
    }
}
