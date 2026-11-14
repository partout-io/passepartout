// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0
package com.algoritmico.passepartout.ui.profile.modules

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.PasswordVisualTransformation
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.observables.ProfileEditor
import com.algoritmico.passepartout.ui.theme.LocalTheme
import io.partout.models.TaggedModuleOpenVPN

@Composable
fun OpenVPNCredentialsView(module: TaggedModuleOpenVPN, editor: ProfileEditor) {
    val theme = LocalTheme.current
    val credentials = module.value.credentials
    Column(
        modifier = Modifier.padding(theme.spacing.large),
        verticalArrangement = Arrangement.spacedBy(theme.spacing.medium)
    ) {
        OutlinedTextField(
            value = credentials?.username.orEmpty(),
            onValueChange = { editor.credentials(module.value.id, it, credentials?.password.orEmpty()) },
            label = { Text(stringResource(R.string.global_nouns_username)) },
            keyboardOptions = KeyboardOptions(autoCorrectEnabled = false),
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )
        OutlinedTextField(
            value = credentials?.password.orEmpty(),
            onValueChange = { editor.credentials(module.value.id, credentials?.username.orEmpty(), it) },
            label = { Text(stringResource(R.string.global_nouns_password)) },
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )
    }
}
