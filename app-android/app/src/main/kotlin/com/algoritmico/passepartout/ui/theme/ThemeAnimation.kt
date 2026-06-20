// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.theme

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.Crossfade
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FiniteAnimationSpec
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color

@Composable
fun <T> ThemeNavigationAnimatedContent(
    targetState: T,
    routeIndex: (T) -> Int,
    modifier: Modifier = Modifier,
    label: String = "Theme navigation",
    content: @Composable (T) -> Unit
) {
    val theme = LocalTheme.current
    if (!theme.animation.isEnabled) {
        Box(modifier = modifier) {
            content(targetState)
        }
        return
    }

    AnimatedContent(
        modifier = modifier,
        targetState = targetState,
        transitionSpec = {
            val direction = if (routeIndex(targetState) > routeIndex(initialState)) {
                AnimatedContentTransitionScope.SlideDirection.Left
            } else {
                AnimatedContentTransitionScope.SlideDirection.Right
            }
            slideIntoContainer(
                towards = direction,
                animationSpec = theme.animationSpec()
            ) togetherWith slideOutOfContainer(
                towards = direction,
                animationSpec = theme.animationSpec()
            ) using SizeTransform(clip = false)
        },
        label = label
    ) { state ->
        content(state)
    }
}

@Composable
fun <T> ThemeCrossfade(
    targetState: T,
    modifier: Modifier = Modifier,
    label: String = "Theme crossfade",
    content: @Composable (T) -> Unit
) {
    val theme = LocalTheme.current
    if (!theme.animation.isEnabled) {
        Box(modifier = modifier) {
            content(targetState)
        }
        return
    }

    Crossfade(
        targetState = targetState,
        modifier = modifier,
        animationSpec = theme.animationSpec(),
        label = label
    ) { state ->
        content(state)
    }
}

@Composable
fun animateThemeColorAsState(
    targetValue: Color,
    label: String
): State<Color> {
    val theme = LocalTheme.current
    return animateColorAsState(
        targetValue = targetValue,
        animationSpec = theme.animationSpec(),
        label = label
    )
}

private fun <T> Theme.animationSpec(): FiniteAnimationSpec<T> {
    return if (animation.isEnabled) {
        tween()
    } else {
        snap()
    }
}
