// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.theme

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path

@Composable
fun ThemeNavigatingButton(
    title: String,
    trailingText: String? = null,
    onClick: () -> Unit
) {
    val theme = LocalTheme.current
    ListItem(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        headlineContent = {
            Text(title)
        },
        trailingContent = {
            if (trailingText != null) {
                ThemeTrailingValue(trailingText)
            } else {
                Icon(
                    imageVector = navigateIcon(theme),
                    contentDescription = null
                )
            }
        }
    )
}

private fun navigateIcon(
    theme: Theme
): ImageVector {
    return ImageVector.Builder(
        name = "Navigate",
        defaultWidth = theme.icon.size,
        defaultHeight = theme.icon.size,
        viewportWidth = 24f,
        viewportHeight = 24f
    ).apply {
        path(
            fill = SolidColor(theme.colors.icon),
            pathFillType = PathFillType.NonZero
        ) {
            moveTo(10f, 6f)
            lineTo(8.59f, 7.41f)
            lineTo(13.17f, 12f)
            lineTo(8.59f, 16.59f)
            lineTo(10f, 18f)
            lineTo(16f, 12f)
            close()
        }
    }.build()
}
