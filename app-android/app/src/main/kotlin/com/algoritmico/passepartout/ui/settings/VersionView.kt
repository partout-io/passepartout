// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.extensions.versionString
import com.algoritmico.passepartout.observables.LocalAppConfiguration
import com.algoritmico.passepartout.ui.theme.ThemeLogo

@Composable
fun VersionView(
    modifier: Modifier = Modifier
) {
    var isChangelogPresented by rememberSaveable {
        mutableStateOf(false)
    }

    BackHandler(enabled = isChangelogPresented) {
        isChangelogPresented = false
    }

    if (isChangelogPresented) {
        ChangelogView(modifier = modifier)
    } else {
        VersionContentView(
            modifier = modifier,
            onChangelog = {
                isChangelogPresented = true
            }
        )
    }
}

@Composable
private fun VersionContentView(
    modifier: Modifier,
    onChangelog: () -> Unit
) {
    val appConfiguration = LocalAppConfiguration.current
    val appName = appConfiguration.bundle.displayName

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        ThemeLogo(
            modifier = Modifier.size(dimensionResource(R.dimen.theme_logo_size))
        )
        Spacer(modifier = Modifier.height(24.dp))
        Text(
            text = appName,
            style = MaterialTheme.typography.displaySmall,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = appConfiguration.bundle.versionString,
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(24.dp))
        Text(
            text = versionMessage(appName),
            modifier = Modifier.fillMaxWidth(),
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(24.dp))
        Button(
            onClick = onChangelog
        ) {
            Text("Changelog")
        }
    }
}

private fun versionMessage(
    appName: String
): String {
    return "$appName is a project maintained by Davide De Rosa (keeshux).\n\n" +
        "Source code is publicly available on GitHub under the GPLv3, " +
        "you can find links in the home page."
}
