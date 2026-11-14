// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import androidx.compose.runtime.Composable
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.theme.ThemeDetailRow
import io.partout.models.CustomModule

@Composable
internal fun CustomModuleView(module: CustomModule, onOpenContent: (String, String) -> Unit) {
    ThemeDetailRow(R.string.global_nouns_configuration, module.json.toString(), onOpenContent = onOpenContent)
}
