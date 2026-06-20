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
    HorizontalDivider(modifier = Modifier.padding(start = Theme.Spacing.large))
}

@Composable
fun ThemeListSectionHeader(
    title: String
) {
    Text(
        text = title,
        modifier = Modifier.padding(
            start = Theme.Spacing.large,
            top = Theme.Spacing.xLarge,
            end = Theme.Spacing.large,
            bottom = Theme.Spacing.small
        ),
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.primary,
        fontWeight = Theme.Weight.relevant
    )
}

@Composable
private fun ThemeListSectionFooter(
    text: String
) {
    Text(
        text = text,
        modifier = Modifier.padding(
            start = Theme.Spacing.large,
            top = Theme.Spacing.small,
            end = Theme.Spacing.large,
            bottom = Theme.Spacing.medium
        ),
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
}
