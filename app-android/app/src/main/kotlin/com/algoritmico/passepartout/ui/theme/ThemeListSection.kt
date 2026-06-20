// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.theme

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

@Composable
fun ThemeListSection(
    header: String? = null,
    footer: String? = null,
    content: @Composable () -> Unit = {}
) {
    Column {
        if (header != null) {
            ThemeListSectionHeader(header)
        }
        content()
        ThemeListDivider()
        if (footer != null) {
            ThemeListSectionFooter(footer)
        }
    }
}

@Composable
fun ThemeListDivider() {
    val theme = LocalTheme.current
    HorizontalDivider(modifier = Modifier.padding(start = theme.spacing.large))
}

@Composable
fun ThemeListSectionHeader(
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
