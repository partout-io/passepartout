// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.theme

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.darkColorScheme as materialDarkColorScheme
import androidx.compose.material3.lightColorScheme as materialLightColorScheme
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

val LocalTheme = compositionLocalOf {
    Theme()
}

@Immutable
data class Theme(
    val lightColorScheme: ColorScheme = DefaultLightColorScheme,
    val darkColorScheme: ColorScheme = DefaultDarkColorScheme,
    val spacing: ThemeSpacing = ThemeSpacing(),
    val icon: ThemeIcon = ThemeIcon(),
    val progress: ThemeProgress = ThemeProgress(),
    val weight: ThemeWeight = ThemeWeight(),
    val colors: ThemeColors = ThemeColors(),
    val alpha: ThemeAlpha = ThemeAlpha()
) {
    fun colorScheme(
        isDark: Boolean
    ): ColorScheme {
        return if (isDark) {
            darkColorScheme
        } else {
            lightColorScheme
        }
    }

    private companion object {
        val DefaultLightColorScheme = materialLightColorScheme(
            primary = Color(0xFF9A571B),
            onPrimary = Color(0xFFFFFFFF),
            primaryContainer = Color(0xFFFFDCC1),
            onPrimaryContainer = Color(0xFF311300),
            inversePrimary = Color(0xFFFFB878)
        )

        val DefaultDarkColorScheme = materialDarkColorScheme(
            primary = Color(0xFFFFB878),
            onPrimary = Color(0xFF4A2600),
            primaryContainer = Color(0xFF6B3A0E),
            onPrimaryContainer = Color(0xFFFFDCC1),
            inversePrimary = Color(0xFF9A571B)
        )
    }
}

@Immutable
data class ThemeSpacing(
    val xSmall: Dp = 4.dp,
    val small: Dp = 8.dp,
    val medium: Dp = 12.dp,
    val large: Dp = 16.dp,
    val xLarge: Dp = 20.dp,
    val xxLarge: Dp = 24.dp
)

@Immutable
data class ThemeIcon(
    val size: Dp = 24.dp
)

@Immutable
data class ThemeProgress(
    val smallSize: Dp = 18.dp,
    val thinStroke: Dp = 2.dp
)

@Immutable
data class ThemeWeight(
    val relevant: FontWeight = FontWeight.SemiBold,
    val strong: FontWeight = FontWeight.Bold,
    val secondary: FontWeight = FontWeight.Light
)

@Immutable
data class ThemeColors(
    val icon: Color = Color.Black,
    val active: Color = Color(0xFF00AA00),
    val pending: Color = Color(0xFFFF9800),
    val error: Color = Color(0xFFD32F2F)
)

@Immutable
data class ThemeAlpha(
    val secondaryStatus: Float = 0.72f
)
