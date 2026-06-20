// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.theme

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path

enum class ThemeImageName {
    add,
    close,
    contextRemove,
    navigate,
    profileImportFile,
    settings
}

@Composable
fun ThemeImage(
    name: ThemeImageName,
    contentDescription: String?,
    modifier: Modifier = Modifier
) {
    Icon(
        imageVector = LocalTheme.current.imageVector(name),
        contentDescription = contentDescription,
        modifier = modifier
    )
}

fun Theme.imageVector(
    name: ThemeImageName
): ImageVector {
    return when (name) {
        ThemeImageName.add -> Icons.Filled.Add
        ThemeImageName.close -> Icons.Filled.Close
        ThemeImageName.contextRemove -> Icons.Filled.Delete
        ThemeImageName.navigate -> Icons.AutoMirrored.Filled.KeyboardArrowRight
        ThemeImageName.profileImportFile -> profileImportFileImageVector()
        ThemeImageName.settings -> Icons.Filled.Settings
    }
}

private fun Theme.profileImportFileImageVector(): ImageVector {
    return ImageVector.Builder(
        name = "ProfileImportFile",
        defaultWidth = Icons.Filled.Add.defaultWidth,
        defaultHeight = Icons.Filled.Add.defaultHeight,
        viewportWidth = 24f,
        viewportHeight = 24f
    ).apply {
        path(
            fill = SolidColor(colors.icon),
            pathFillType = PathFillType.NonZero
        ) {
            moveTo(14f, 2f)
            horizontalLineTo(6f)
            curveTo(4.9f, 2f, 4f, 2.9f, 4f, 4f)
            verticalLineTo(20f)
            curveTo(4f, 21.1f, 4.9f, 22f, 6f, 22f)
            horizontalLineTo(18f)
            curveTo(19.1f, 22f, 20f, 21.1f, 20f, 20f)
            verticalLineTo(8f)
            close()
            moveTo(13f, 9f)
            verticalLineTo(3.5f)
            lineTo(18.5f, 9f)
            close()
            moveTo(13f, 17f)
            verticalLineTo(14f)
            horizontalLineTo(8f)
            verticalLineTo(12f)
            horizontalLineTo(13f)
            verticalLineTo(9f)
            lineTo(17f, 13f)
            close()
        }
    }.build()
}
