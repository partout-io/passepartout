// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.extensions.urlForIssue
import com.algoritmico.passepartout.business.extensions.versionString
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.models.ChangelogEntry
import com.algoritmico.passepartout.observables.safeOpenUri
import com.algoritmico.passepartout.ui.LocalAndroidConstants
import com.algoritmico.passepartout.ui.LocalAppConfiguration
import com.algoritmico.passepartout.ui.LocalErrorHandler
import com.algoritmico.passepartout.ui.LocalVersionObservable
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.ThemeEmptyMessage
import com.algoritmico.passepartout.ui.theme.ThemeList
import com.algoritmico.passepartout.ui.theme.ThemeProgressView
import com.algoritmico.passepartout.ui.theme.themeListSection

@Composable
fun ChangelogView(
    modifier: Modifier = Modifier
) {
    val androidConstants = LocalAndroidConstants.current
    val appConfiguration = LocalAppConfiguration.current
    val versionObservable = LocalVersionObservable.current
    val versionNumber = appConfiguration.bundle.versionNumber
    var entries by remember(versionNumber) {
        mutableStateOf(emptyList<ChangelogEntry>())
    }
    var isLoading by remember(versionNumber) {
        mutableStateOf(true)
    }
    val theme = LocalTheme.current

    LaunchedEffect(versionNumber, versionObservable, androidConstants.tags.app) {
        isLoading = true
        entries = runCatchingNonFatal {
            versionObservable.fetchChangelog(versionNumber)
        }.getOrElse {
            AppLog.w(androidConstants.tags.app, "Unable to load changelog", it)
            emptyList()
        }
        isLoading = false
    }

    when {
        isLoading -> ThemeProgressView(modifier = modifier)
        entries.isEmpty() -> ThemeEmptyMessage(
            text = stringResource(R.string.global_nouns_no_content),
            modifier = modifier.padding(theme.spacing.xxLarge)
        )
        else -> ChangelogListView(
            modifier = modifier,
            versionString = appConfiguration.bundle.versionString,
            entries = entries
        )
    }
}

@Composable
private fun ChangelogListView(
    modifier: Modifier,
    versionString: String,
    entries: List<ChangelogEntry>
) {
    val appConfiguration = LocalAppConfiguration.current
    val uriHandler = LocalUriHandler.current
    val errorHandler = LocalErrorHandler.current
    ThemeList(modifier = modifier) {
        themeListSection(header = versionString) {
            items(
                items = entries,
                key = { it.id }
            ) { entry ->
                val issueURL = entry.issue?.let {
                    appConfiguration.constants.github.urlForIssue(it)
                }
                ListItem(
                    modifier = Modifier
                        .fillMaxWidth()
                        .then(
                            if (issueURL != null) {
                                Modifier.clickable {
                                    uriHandler.safeOpenUri(issueURL, errorHandler)
                                }
                            } else {
                                Modifier
                            }
                        ),
                    headlineContent = {
                        Text(entry.comment)
                    }
                )
            }
        }
    }
}
