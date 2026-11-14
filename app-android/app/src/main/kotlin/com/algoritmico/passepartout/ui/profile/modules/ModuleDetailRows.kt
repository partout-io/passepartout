// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import androidx.annotation.StringRes
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.theme.ThemeListSectionHeader
import com.algoritmico.passepartout.ui.theme.ThemeNavigatingButton

@Composable
internal fun DetailSection(@StringRes title: Int) {
    ThemeListSectionHeader(stringResource(title))
}

@Composable
internal fun DetailRow(@StringRes title: Int, value: Any?, onOpenContent: ((String, String) -> Unit)? = null) {
    DetailRow(stringResource(title), value, onOpenContent)
}

@Composable
internal fun DetailRow(label: String, value: Any?, onOpenContent: ((String, String) -> Unit)? = null) {
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
        supportingContent = { SelectionContainer { Text(text) } }
    )
}

internal fun hasContent(vararg values: Any?): Boolean = values.any { value ->
    when (value) {
        null -> false
        is Collection<*> -> value.isNotEmpty()
        is String -> value.isNotEmpty()
        else -> true
    }
}
