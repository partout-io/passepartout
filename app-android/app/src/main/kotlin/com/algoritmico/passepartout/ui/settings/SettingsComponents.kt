// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
internal fun SettingsSection(
    header: String? = null,
    footer: String? = null,
    content: @Composable () -> Unit = {}
) {
    Column {
        if (header != null) {
            SettingsSectionHeader(header)
        }
        content()
        HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
        if (footer != null) {
            SettingsSectionFooter(footer)
        }
    }
}

@Composable
internal fun SettingsSectionHeader(
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
internal fun SettingsProgressView(
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator()
    }
}

@Composable
internal fun SettingsEmptyContentView(
    modifier: Modifier = Modifier,
    text: String = "No content"
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun SettingsSectionFooter(
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
