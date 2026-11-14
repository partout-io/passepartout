// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0
package com.algoritmico.passepartout.ui.profile.modules

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.ThemeTextField
import io.partout.models.OpenVPNModule
import io.partout.models.OpenVPNCredentials
import io.partout.models.OpenVPNCredentialsOTPMethod

@Composable
fun OpenVPNCredentialsView(module: OpenVPNModule, onChange: (OpenVPNModule) -> Unit) {
    val theme = LocalTheme.current
    val credentials = module.credentials
        ?: OpenVPNCredentials("", "", OpenVPNCredentialsOTPMethod.none)
    Column(
        modifier = Modifier.padding(theme.spacing.large),
        verticalArrangement = Arrangement.spacedBy(theme.spacing.medium)
    ) {
        ThemeTextField(
            value = credentials.username,
            onValueChange = { onChange(module.copy(credentials = credentials.copy(username = it))) },
            label = stringResource(R.string.global_nouns_username),
            keyboardOptions = KeyboardOptions(autoCorrectEnabled = false),
        )
        ThemeTextField(
            value = credentials.password,
            onValueChange = { onChange(module.copy(credentials = credentials.copy(password = it))) },
            label = stringResource(R.string.global_nouns_password),
            secure = true,
        )
    }
}
