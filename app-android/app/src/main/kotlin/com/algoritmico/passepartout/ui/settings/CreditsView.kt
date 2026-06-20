// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.context.Tags
import com.algoritmico.passepartout.context.credits
import com.algoritmico.passepartout.models.Credits
import com.algoritmico.passepartout.models.CreditsLicensesInner
import com.algoritmico.passepartout.models.CreditsNoticesInner
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.ThemeList
import com.algoritmico.passepartout.ui.theme.ThemeProgressView
import com.algoritmico.passepartout.ui.theme.ThemeProgressViewStyle
import com.algoritmico.passepartout.ui.theme.ThemeTrailingValue
import com.algoritmico.passepartout.ui.theme.themeListSection
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.URL
import java.util.Locale

@Composable
fun CreditsView(
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val credits = remember(context) {
        runCatchingNonFatal {
            context.credits()
        }.getOrElse {
            AppLog.w(Tags.APP, "Unable to load credits", it)
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
    val licensesHeader = stringResource(R.string.views_settings_credits_licenses)
    val noticesHeader = stringResource(R.string.views_settings_credits_notices)
    val translationsHeader = stringResource(R.string.views_settings_credits_translations)

    ThemeList(modifier = modifier) {
        if (licenses.isNotEmpty()) {
            themeListSection(header = licensesHeader) {
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
                            ThemeTrailingValue(license.licenseName)
                        }
                    )
                }
            }
        }
        if (notices.isNotEmpty()) {
            themeListSection(header = noticesHeader) {
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
            }
        }
        if (languages.isNotEmpty()) {
            themeListSection(header = translationsHeader) {
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
                    ThemeTrailingValue(author)
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
    val theme = LocalTheme.current
    val context = LocalContext.current

    LaunchedEffect(context, license.licenseURL, content) {
        if (content == null) {
            val loadedContent = withContext(Dispatchers.IO) {
                runCatchingNonFatal {
                    URL(license.licenseURL).readText()
                }.getOrElse {
                    context.getString(R.string.errors_app_other)
                }
            }
            onContent(loadedContent)
        }
    }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(theme.spacing.large)
    ) {
        item {
            Text(
                text = license.name,
                style = MaterialTheme.typography.titleLarge
            )
        }
        if (content == null) {
            item {
                ThemeProgressView(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = theme.spacing.xxLarge),
                    style = ThemeProgressViewStyle.centered
                )
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
    val theme = LocalTheme.current

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(theme.spacing.large)
    ) {
        Text(
            text = notice.name,
            style = MaterialTheme.typography.titleLarge
        )
        Text(
            text = notice.message,
            modifier = Modifier.padding(top = theme.spacing.large),
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
