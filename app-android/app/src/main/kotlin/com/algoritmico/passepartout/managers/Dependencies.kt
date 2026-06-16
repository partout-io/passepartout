// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.managers

import com.algoritmico.passepartout.PassepartoutWrapper
import com.algoritmico.passepartout.extensions.betaConfigURL
import com.algoritmico.passepartout.extensions.configURL
import com.algoritmico.passepartout.extensions.urlForChangelog
import com.algoritmico.passepartout.models.AppConfiguration
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.models.ChangelogEntry
import com.algoritmico.passepartout.models.DistributionTarget
import com.algoritmico.passepartout.strategy.FileProfileRepository
import com.algoritmico.passepartout.strategy.GitHubConfigStrategy
import com.algoritmico.passepartout.strategy.GitHubReleaseStrategy
import com.algoritmico.passepartout.strategy.URLFetcher
import java.io.File

fun AppConfiguration.newProfileManager(
    logTag: String,
    library: PassepartoutWrapper,
    directory: File
): ProfileManager {
    return ProfileManager(
        logTag,
        library,
        repository = FileProfileRepository(directory)
    )
}

fun AppConfiguration.newConfigManager(
    logTag: String,
    isBeta: Boolean
): ConfigManager {
    val url = if (isBeta) constants.websites.betaConfigURL else constants.websites.configURL
    // FIXME: ###, Move ttl=0.1 and isCached=false to constants.json
    val ttl = constants.websites.configTTL * if (isBeta) 0.1 else 1.0
    val isCached = false
    return ConfigManager(
        logTag,
        strategy = GitHubConfigStrategy(
            logTag = logTag,
            url = url,
            ttl = ttl,
            fetcher = { url ->
                URLFetcher.fetch(url, isCached, constants.url.timeoutInterval)
            }
        ),
        buildNumber = bundle.buildNumber
    )
}

fun AppConfiguration.newVersionChecker(
    logTag: String,
    preferences: () -> AppPreferences,
    updatePreferences: suspend (
        fields: List<AppPreferenceKey>,
        transform: (AppPreferences) -> AppPreferences
    ) -> Unit
): VersionChecker {
    return VersionChecker(
        logTag = logTag,
        preferences = preferences,
        updatePreferences = updatePreferences,
        strategy = GitHubReleaseStrategy(
            logTag = logTag,
            releaseURL = constants.github.latestReleaseURL,
            rateLimit = constants.url.versionRateLimit,
            fetcher = { url ->
                URLFetcher.fetch(url, false, constants.url.timeoutInterval)
            }
        ),
        currentVersion = bundle.versionNumber,
        downloadURL = when (bundle.distributionTarget) {
            DistributionTarget.appStore -> constants.websites.appStoreDownloadURL
            DistributionTarget.developerID -> constants.websites.macDownloadURL
            DistributionTarget.enterprise -> error("No URL for enterprise distribution")
        },
        changelogFetcher = { version ->
            val url = constants.github.urlForChangelog(version)
            val text = URLFetcher.fetch(url, false, constants.url.timeoutInterval).decodeToString()
            text.split("\n")
                .filter { it.isNotEmpty() }
                .mapIndexedNotNull { index, line ->
                    line.toChangelogEntry(index)
                }
        }
    )
}

private fun String.toChangelogEntry(id: Int): ChangelogEntry? {
    val entryPrefix = "* "
    if (!startsWith(entryPrefix)) {
        return null
    }

    val components = removePrefix(entryPrefix)
        .split(" ")
        .toMutableList()

    var issue: Int? = null
    val last = components.lastOrNull()
    if (components.size >= 2 && last != null && last.startsWith("(#") && last.endsWith(")")) {
        val issueString = last.substring(2, last.length - 1)
        val parsedIssue = issueString.toIntOrNull()
        if (parsedIssue != null) {
            components.removeLast()
            issue = parsedIssue
        }
    }

    return ChangelogEntry(
        id = id,
        comment = components.joinToString(" "),
        issue = issue
    )
}
