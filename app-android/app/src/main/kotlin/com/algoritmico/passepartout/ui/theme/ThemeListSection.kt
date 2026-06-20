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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

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
        HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
        if (footer != null) {
            ThemeListSectionFooter(footer)
        }
    }
}

@Composable
fun ThemeListSectionHeader(
    title: String
) {
    Text(
        text = title,
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

@Composable
private fun ThemeListSectionFooter(
    text: String
) {
    Text(
        text = text,
        modifier = Modifier.padding(
            start = 16.dp,
            top = 8.dp,
            end = 16.dp,
            bottom = 12.dp
        ),
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
}
