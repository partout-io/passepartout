// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.theme

import androidx.compose.foundation.clickable
import androidx.compose.material3.ListItem
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.ui.LocalErrorHandler
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

@Composable
fun ThemeSwitchRow(
    title: String,
    checkedFlow: Flow<Boolean>,
    modifier: Modifier = Modifier,
    supportingText: String? = null,
    enabled: Boolean = true,
    initialValue: Boolean = false,
    onCheckedChange: suspend (Boolean) -> Unit
) {
    val checked by checkedFlow.collectAsStateWithLifecycle(
        initialValue = initialValue
    )
    ThemeSwitchRow(
        title = title,
        checked = checked,
        modifier = modifier,
        supportingText = supportingText,
        enabled = enabled,
        onCheckedChange = onCheckedChange
    )
}

@Composable
fun ThemeSwitchRow(
    title: String,
    checked: Boolean,
    modifier: Modifier = Modifier,
    supportingText: String? = null,
    enabled: Boolean = true,
    onCheckedChange: suspend (Boolean) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val errorHandler = LocalErrorHandler.current

    fun update(isChecked: Boolean) {
        coroutineScope.launch {
            runCatchingNonFatal {
                onCheckedChange(isChecked)
            }.onFailure {
                errorHandler.report(it)
            }
        }
    }

    ListItem(
        headlineContent = {
            Text(title)
        },
        supportingContent = supportingText?.let { text ->
            {
                Text(text)
            }
        },
        trailingContent = {
            Switch(
                checked = checked,
                enabled = enabled,
                onCheckedChange = ::update
            )
        },
        modifier = modifier.clickable(
            enabled = enabled
        ) {
            update(!checked)
        }
    )
}
