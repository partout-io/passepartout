// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.theme

import androidx.annotation.StringRes
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import com.algoritmico.passepartout.R

@Composable
fun ThemeDetailRow(@StringRes title: Int, value: Any?, onOpenContent: ((String, String) -> Unit)? = null, valueFontFamily: FontFamily? = null) {
    ThemeDetailRow(stringResource(title), value, onOpenContent, valueFontFamily)
}

@Composable
fun ThemeDetailRow(label: String, value: Any?, onOpenContent: ((String, String) -> Unit)? = null, valueFontFamily: FontFamily? = null) {
    if (value == null) return
    val text = when (value) {
        is Boolean -> stringResource(if (value) R.string.global_nouns_yes else R.string.global_nouns_no)
        is List<*> -> value.joinToString("\n")
        else -> value.toString()
    }
    if (text.isEmpty()) return
    if (onOpenContent != null) {
        ThemeNavigatingButton(title = label, onClick = { onOpenContent(label, text) })
        return
    }
    ListItem(
        headlineContent = { Text(label) },
        supportingContent = { SelectionContainer { Text(text, fontFamily = valueFontFamily) } }
    )
}
