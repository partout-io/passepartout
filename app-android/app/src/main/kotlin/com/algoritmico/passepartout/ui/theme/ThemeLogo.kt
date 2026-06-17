// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.theme

import androidx.compose.foundation.Image
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import com.algoritmico.passepartout.R

@Composable
fun ThemeLogo(
    modifier: Modifier = Modifier
) {
    Image(
        painter = painterResource(R.drawable.app_logo),
        contentDescription = null,
        modifier = modifier
    )
}
