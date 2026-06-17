// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import android.util.Log
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.algoritmico.passepartout.business.injection.credits
import com.algoritmico.passepartout.business.models.Credits
import com.algoritmico.passepartout.business.models.CreditsLicensesInner
import com.algoritmico.passepartout.business.models.CreditsNoticesInner
import com.algoritmico.passepartout.ui.theme.ListItemTrailingText
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.URL
import java.util.Locale

private const val TAG = "CreditsView"

@Composable
fun CreditsView(
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val credits = remember(context) {
        runCatching {
            context.credits()
        }.getOrElse {
            Log.w(TAG, "Unable to load credits", it)
            Credits(emptyList(), emptyList(), emptyMap())
        }
    }
    val contentForLicense = remember {
        mutableStateMapOf<String, String>()
    }
    var selection by remember {
        mutableStateOf<CreditsSelection?>(null)
    }

    BackHandler(enabled = selection != null) {
        selection = null
    }

    when (val currentSelection = selection) {
        is CreditsSelection.License -> {
            LicenseView(
                modifier = modifier,
                license = currentSelection.license,
                content = contentForLicense[currentSelection.license.name],
                onContent = { content ->
                    contentForLicense[currentSelection.license.name] = content
                }
            )
        }
        is CreditsSelection.Notice -> {
            NoticeView(
                modifier = modifier,
                notice = currentSelection.notice
            )
        }
        null -> {
            CreditsListView(
                modifier = modifier,
                credits = credits,
                onLicense = {
                    selection = CreditsSelection.License(it)
                },
                onNotice = {
                    selection = CreditsSelection.Notice(it)
                }
            )
        }
    }
}

@Composable
private fun CreditsListView(
    modifier: Modifier,
    credits: Credits,
    onLicense: (CreditsLicensesInner) -> Unit,
    onNotice: (CreditsNoticesInner) -> Unit
) {
    val licenses = remember(credits) {
        credits.licenses.sortedBy { it.name.lowercase() }
    }
    val notices = remember(credits) {
        credits.notices.sortedBy { it.name.lowercase() }
    }
    val languages = remember(credits) {
        credits.translations.keys.sortedBy { it.localizedLanguageName() }
    }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        if (licenses.isNotEmpty()) {
            item {
                CreditsSectionHeader("Licenses")
            }
            items(
                items = licenses,
                key = { it.name }
            ) { license ->
                ListItem(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable {
                            onLicense(license)
                        },
                    headlineContent = {
                        Text(license.name)
                    },
                    trailingContent = {
                        ListItemTrailingText(license.licenseName)
                    }
                )
            }
            item {
                HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
            }
        }

        if (notices.isNotEmpty()) {
            item {
                CreditsSectionHeader("Notices")
            }
            items(
                items = notices,
                key = { it.name }
            ) { notice ->
                ListItem(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable {
                            onNotice(notice)
                        },
                    headlineContent = {
                        Text(notice.name)
                    }
                )
            }
            item {
                HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
            }
        }

        if (languages.isNotEmpty()) {
            item {
                CreditsSectionHeader("Translations")
            }
            items(
                items = languages,
                key = { it }
            ) { code ->
                TranslationRow(
                    language = code.localizedLanguageName(),
                    authors = credits.translations[code].orEmpty()
                )
            }
        }
    }
}

@Composable
private fun CreditsSectionHeader(
    title: String
) {
    Text(
        text = title,
        modifier = Modifier.padding(
            start = 16.dp,
            top = 20.dp,
            end = 16.dp,
            bottom = 8.dp
        ),
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.primary,
        fontWeight = FontWeight.SemiBold
    )
}

@Composable
private fun TranslationRow(
    language: String,
    authors: List<String>
) {
    ListItem(
        headlineContent = {
            Text(language)
        },
        trailingContent = {
            Column(
                horizontalAlignment = Alignment.End
            ) {
                authors.forEach { author ->
                    ListItemTrailingText(author)
                }
            }
        }
    )
}

@Composable
private fun LicenseView(
    modifier: Modifier,
    license: CreditsLicensesInner,
    content: String?,
    onContent: (String) -> Unit
) {
    LaunchedEffect(license.licenseURL, content) {
        if (content == null) {
            val loadedContent = withContext(Dispatchers.IO) {
                runCatching {
                    URL(license.licenseURL).readText()
                }.getOrElse {
                    if (it !is Exception) {
                        throw it
                    }
                    "Unable to load license: ${it.localizedMessage ?: it::class.java.simpleName}"
                }
            }
            onContent(loadedContent)
        }
    }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp)
    ) {
        item {
            Text(
                text = license.name,
                style = MaterialTheme.typography.titleLarge
            )
        }
        if (content == null) {
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 24.dp),
                    horizontalArrangement = Arrangement.Center
                ) {
                    CircularProgressIndicator()
                }
            }
        } else {
            items(content.lines()) { line ->
                Text(
                    text = line,
                    modifier = Modifier.fillMaxWidth(),
                    fontFamily = FontFamily.Monospace,
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}

@Composable
private fun NoticeView(
    modifier: Modifier,
    notice: CreditsNoticesInner
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text(
            text = notice.name,
            style = MaterialTheme.typography.titleLarge
        )
        Text(
            text = notice.message,
            modifier = Modifier.padding(top = 16.dp),
            style = MaterialTheme.typography.bodyLarge
        )
    }
}

private fun String.localizedLanguageName(): String {
    return Locale.forLanguageTag(this)
        .getDisplayLanguage(Locale.getDefault())
        .ifBlank {
            this
        }
}

private sealed interface CreditsSelection {
    data class License(
        val license: CreditsLicensesInner
    ) : CreditsSelection

    data class Notice(
        val notice: CreditsNoticesInner
    ) : CreditsSelection
}
