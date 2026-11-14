// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.theme.ThemeNavigatingButton
import io.partout.models.CustomModule

@Composable
internal fun CustomModuleView(module: CustomModule, onOpenContent: (String, String) -> Unit) {
    val title = stringResource(R.string.global_nouns_configuration)
    ThemeNavigatingButton(title = title, onClick = { onOpenContent(title, module.json.toString()) })
}
