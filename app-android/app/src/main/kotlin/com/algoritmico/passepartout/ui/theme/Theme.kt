// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.theme

import androidx.compose.material3.darkColorScheme as materialDarkColorScheme
import androidx.compose.material3.lightColorScheme as materialLightColorScheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

object Theme {
    val lightColorScheme = materialLightColorScheme(
        primary = Color(0xFF9A571B),
        onPrimary = Color(0xFFFFFFFF),
        primaryContainer = Color(0xFFFFDCC1),
        onPrimaryContainer = Color(0xFF311300),
        inversePrimary = Color(0xFFFFB878)
    )

    val darkColorScheme = materialDarkColorScheme(
        primary = Color(0xFFFFB878),
        onPrimary = Color(0xFF4A2600),
        primaryContainer = Color(0xFF6B3A0E),
        onPrimaryContainer = Color(0xFFFFDCC1),
        inversePrimary = Color(0xFF9A571B)
    )

    object Spacing {
        val xSmall = 4.dp
        val small = 8.dp
        val medium = 12.dp
        val large = 16.dp
        val xLarge = 20.dp
        val xxLarge = 24.dp
    }

    object Icon {
        val size = 24.dp
    }

    object Progress {
        val smallSize = 18.dp
        val thinStroke = 2.dp
    }

    object Weight {
        val relevant = FontWeight.SemiBold
        val strong = FontWeight.Bold
        val secondary = FontWeight.Light
    }

    object Colors {
        val icon = Color.Black
        val active = Color(0xFF00AA00)
        val pending = Color(0xFFFF9800)
        val error = Color(0xFFD32F2F)
    }

    object Alpha {
        const val secondaryStatus = 0.72f
    }
}
