// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import com.algoritmico.passepartout.context.AppLog
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
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
import androidx.compose.ui.unit.dp
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.extensions.urlForIssue
import com.algoritmico.passepartout.business.extensions.versionString
import com.algoritmico.passepartout.models.ChangelogEntry
import com.algoritmico.passepartout.observables.LocalAppConfiguration
import com.algoritmico.passepartout.observables.LocalErrorHandler
import com.algoritmico.passepartout.observables.LocalVersionObservable
import com.algoritmico.passepartout.observables.safeOpenUri
import com.algoritmico.passepartout.ui.theme.ThemeEmptyMessage
import com.algoritmico.passepartout.ui.theme.ThemeListSectionHeader
import com.algoritmico.passepartout.ui.theme.ThemeProgressView

private const val TAG = "ChangelogView"

@Composable
fun ChangelogView(
    modifier: Modifier = Modifier
) {
    val appConfiguration = LocalAppConfiguration.current
    val versionObservable = LocalVersionObservable.current
    val versionNumber = appConfiguration.bundle.versionNumber
    var entries by remember(versionNumber) {
        mutableStateOf(emptyList<ChangelogEntry>())
    }
    var isLoading by remember(versionNumber) {
        mutableStateOf(true)
    }

    LaunchedEffect(versionNumber, versionObservable) {
        isLoading = true
        entries = runCatchingNonFatal {
            versionObservable.fetchChangelog(versionNumber)
        }.getOrElse {
            AppLog.w(TAG, "Unable to load changelog", it)
            emptyList()
        }
        isLoading = false
    }

    when {
        isLoading -> ThemeProgressView(modifier = modifier)
        entries.isEmpty() -> ThemeEmptyMessage(
            text = "No content",
            modifier = modifier.padding(24.dp)
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

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = 8.dp),
        verticalArrangement = Arrangement.Top
    ) {
        item {
            ThemeListSectionHeader(versionString)
        }
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
        item {
            HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
        }
    }
}
