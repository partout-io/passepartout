// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.extensions

import com.algoritmico.passepartout.PassepartoutWrapper
import com.algoritmico.passepartout.managers.ConfigManager
import com.algoritmico.passepartout.managers.ProfileManager
import com.algoritmico.passepartout.managers.VersionChecker
import com.algoritmico.passepartout.models.AppConfiguration
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.models.DistributionTarget
import com.algoritmico.passepartout.observables.UserPreferencesObservable
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
    val timeout = constants.url.timeoutInterval
    val isCached = false
    return ConfigManager(
        logTag,
        strategy = GitHubConfigStrategy(
            logTag = logTag,
            url = url,
            ttl = ttl,
            fetcher = { url ->
                URLFetcher.fetch(url, isCached, timeout)
            }
        ),
        buildNumber = bundle.buildNumber
    )
}

fun AppConfiguration.newVersionChecker(
    logTag: String,
    userPreferencesObservable: UserPreferencesObservable
): VersionChecker {
    // FIXME: ###, Move isCached=false to constants.json
    val changelogURL = constants.github::urlForChangelog
    val timeout = constants.url.timeoutInterval
    val isCached = false
    return VersionChecker(
        logTag = logTag,
        strategy = GitHubReleaseStrategy(
            logTag = logTag,
            releaseURL = constants.github.latestReleaseURL,
            rateLimit = constants.url.versionRateLimit,
            changelogURL = changelogURL,
            fetcher = { url ->
                URLFetcher.fetch(url, isCached, timeout)
            },
            userPreferencesObservable = userPreferencesObservable
        ),
        currentVersion = bundle.versionNumber,
        downloadURL = when (bundle.distributionTarget) {
            DistributionTarget.appStore -> constants.websites.appStoreDownloadURL
            DistributionTarget.developerID -> constants.websites.macDownloadURL
            DistributionTarget.enterprise -> error("No URL for enterprise distribution")
        }
    )
}
