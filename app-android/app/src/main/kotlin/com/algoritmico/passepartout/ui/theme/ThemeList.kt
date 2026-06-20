// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.theme

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

@Composable
fun ThemeList(
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues? = null,
    verticalArrangement: Arrangement.Vertical = Arrangement.Top,
    content: LazyListScope.() -> Unit
) {
    val theme = LocalTheme.current
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = contentPadding ?: PaddingValues(vertical = theme.spacing.small),
        verticalArrangement = verticalArrangement,
        content = content
    )
}

fun LazyListScope.themeListSection(
    header: String? = null,
    footer: String? = null,
    content: LazyListScope.() -> Unit = {}
) {
    if (header != null) {
        item {
            ThemeListSectionHeader(header)
        }
    }
    content()
    item {
        ThemeListDivider()
    }
    if (footer != null) {
        item {
            ThemeListSectionFooter(footer)
        }
    }
}

@Composable
private fun ThemeListDivider() {
    val theme = LocalTheme.current
    HorizontalDivider(modifier = Modifier.padding(start = theme.spacing.large))
}

@Composable
private fun ThemeListSectionHeader(
    title: String
) {
    val theme = LocalTheme.current
    Text(
        text = title,
        modifier = Modifier.padding(
            start = theme.spacing.large,
            top = theme.spacing.xLarge,
            end = theme.spacing.large,
            bottom = theme.spacing.small
        ),
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.primary,
        fontWeight = theme.weight.relevant
    )
}

@Composable
private fun ThemeListSectionFooter(
    text: String
) {
    val theme = LocalTheme.current
    Text(
        text = text,
        modifier = Modifier.padding(
            start = theme.spacing.large,
            top = theme.spacing.small,
            end = theme.spacing.large,
            bottom = theme.spacing.medium
        ),
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
}
