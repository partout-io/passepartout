// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.theme

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

enum class ThemeProgressViewStyle {
    fullScreen,
    centered,
    inlineButton
}

@Composable
fun ThemeProgressView(
    modifier: Modifier = Modifier,
    style: ThemeProgressViewStyle = ThemeProgressViewStyle.fullScreen
) {
    when (style) {
        ThemeProgressViewStyle.fullScreen -> {
            Box(
                modifier = modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        }
        ThemeProgressViewStyle.centered -> {
            Box(
                modifier = modifier,
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        }
        ThemeProgressViewStyle.inlineButton -> {
            CircularProgressIndicator(
                modifier = modifier.size(ButtonDefaults.IconSize),
                color = MaterialTheme.colorScheme.onPrimary
            )
        }
    }
}
