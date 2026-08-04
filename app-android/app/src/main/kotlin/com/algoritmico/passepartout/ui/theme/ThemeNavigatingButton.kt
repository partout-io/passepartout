// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.theme

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

@Composable
fun ThemeNavigatingButton(
    title: String,
    trailingText: String? = null,
    onClick: () -> Unit
) {
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
                ThemeImage(
                    name = ThemeImageName.navigate,
                    contentDescription = null
                )
            }
        }
    )
}
