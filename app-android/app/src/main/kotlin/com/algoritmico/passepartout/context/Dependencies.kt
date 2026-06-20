// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.context

import android.content.Context
import android.content.Intent
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import com.algoritmico.passepartout.PassepartoutVpnService
import com.algoritmico.passepartout.PassepartoutWrapper
import com.algoritmico.passepartout.business.extensions.betaConfigURL
import com.algoritmico.passepartout.business.extensions.configURL
import com.algoritmico.passepartout.business.extensions.urlForChangelog
import com.algoritmico.passepartout.business.managers.ConfigManager
import com.algoritmico.passepartout.business.managers.ProfileManager
import com.algoritmico.passepartout.business.managers.VersionChecker
import com.algoritmico.passepartout.business.strategy.FileProfileRepository
import com.algoritmico.passepartout.business.strategy.GitHubConfigStrategy
import com.algoritmico.passepartout.business.strategy.GitHubReleaseStrategy
import com.algoritmico.passepartout.business.strategy.URLFetcher
import com.algoritmico.passepartout.models.AppConfiguration
import com.algoritmico.passepartout.models.DistributionTarget
import com.algoritmico.passepartout.models.Event
import io.partout.PartoutTunnel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableSharedFlow

//region Managers
fun AppConfiguration.newConfigManager(
    logTag: String,
    isBeta: Boolean,
    eventConstants: AndroidConstants.Events
): ConfigManager {
    val url = if (isBeta) constants.websites.betaConfigURL else constants.websites.configURL
    val ttlFactor = if (isBeta) constants.websites.betaTTLFactor else 1.0
    val ttl = constants.websites.configTTL * ttlFactor
    val isCached = false
    val timeout = constants.url.timeoutInterval
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
        buildNumber = bundle.buildNumber,
        eventConstants = eventConstants
    )
}

fun AppConfiguration.newProfileManager(
    logTag: String,
    applicationContext: Context,
    library: PassepartoutWrapper,
    eventConstants: AndroidConstants.Events
): ProfileManager {
    val localName = constants.containers.local.lowercase()
    val directory = applicationContext.persistentFile(localName)
        .apply {
            mkdirs()
        }
    return ProfileManager(
        logTag,
        library,
        FileProfileRepository(logTag, directory),
        eventConstants = eventConstants
    )
}

fun AppConfiguration.newTunnel(
    logTag: String,
    applicationContext: Context,
    tunnelConstants: AndroidConstants.Tunnel,
    requestVpnPermission: (Intent) -> Unit
): PartoutTunnel {
    return PartoutTunnel(
        logTag,
        applicationContext,
        PassepartoutVpnService::class.java,
        tunnelConstants.isForeground,
        tunnelConstants.logsSnapshots,
        requestVpnPermission
    )
}

fun AppConfiguration.newVersionChecker(
    logTag: String,
    preferences: DataStore<Preferences>,
    coroutineScope: CoroutineScope,
    eventConstants: AndroidConstants.Events
): VersionChecker {
    val changelogURL = constants.github::urlForChangelog
    val isCached = false
    val timeout = constants.url.timeoutInterval
    return VersionChecker(
        logTag = logTag,
        store = preferences,
        coroutineScope = coroutineScope,
        strategy = GitHubReleaseStrategy(
            logTag = logTag,
            releaseURL = constants.github.latestReleaseURL,
            rateLimit = constants.url.versionRateLimit,
            changelogURL = changelogURL,
            fetcher = { url ->
                URLFetcher.fetch(url, isCached, timeout)
            }
        ),
        currentVersion = bundle.versionNumber,
        downloadURL = when (bundle.distributionTarget) {
            DistributionTarget.appStore -> constants.websites.appStoreDownloadURL
            DistributionTarget.developerID -> constants.websites.macDownloadURL
            DistributionTarget.enterprise -> error("No URL for enterprise distribution")
        },
        eventConstants = eventConstants
    )
}

fun newEventFlow(
    eventConstants: AndroidConstants.Events,
    withReplay: Boolean = true
): MutableSharedFlow<Event> {
    return MutableSharedFlow(
        replay = if (withReplay) eventConstants.replay else 0,
        extraBufferCapacity = eventConstants.bufferCapacity
    )
}
//endregion
