// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.injection

import android.content.Context
import android.content.Intent
import com.algoritmico.passepartout.PassepartoutVpnService
import com.algoritmico.passepartout.PassepartoutWrapper
import com.algoritmico.passepartout.business.extensions.betaConfigURL
import com.algoritmico.passepartout.business.extensions.configURL
import com.algoritmico.passepartout.business.extensions.urlForChangelog
import com.algoritmico.passepartout.business.managers.ConfigManager
import com.algoritmico.passepartout.business.managers.ProfileManager
import com.algoritmico.passepartout.business.managers.VersionChecker
import com.algoritmico.passepartout.business.models.AppConfiguration
import com.algoritmico.passepartout.business.models.DistributionTarget
import com.algoritmico.passepartout.business.models.Event
import com.algoritmico.passepartout.business.strategy.FileProfileRepository
import com.algoritmico.passepartout.business.strategy.GitHubConfigStrategy
import com.algoritmico.passepartout.business.strategy.GitHubReleaseStrategy
import com.algoritmico.passepartout.business.strategy.URLFetcher
import com.algoritmico.passepartout.ui.observables.UserPreferencesObservable
import io.partout.PartoutTunnel
import kotlinx.coroutines.flow.MutableSharedFlow

//region Constants
object Tags {
    const val APP = "Passepartout"
    const val SERVICE = "PassepartoutVpnService"
    const val PARTOUT = "Partout"
    const val PARTOUT_JNI = "PartoutJNI"
}

object Files {
    val MIME_TYPES = arrayOf(
        "application/x-openvpn-profile",
        "application/x-wireguard-profile",
        "application/octet-stream",
        "text/*",
        "*/*"
    )

    const val DEFAULT_PROFILE_NAME = "Imported profile"
}

private object Tuning {
    const val TUNNEL_IS_FOREGROUND = true
    const val EVENT_BUFFER_CAPACITY = 64
    const val EVENT_REPLAY = 64
}
//endregion

//region Managers
fun AppConfiguration.newConfigManager(
    logTag: String,
    isBeta: Boolean
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
        buildNumber = bundle.buildNumber
    )
}

fun AppConfiguration.newProfileManager(
    logTag: String,
    applicationContext: Context,
    library: PassepartoutWrapper
): ProfileManager {
    val localName = constants.containers.local.lowercase()
    val directory = applicationContext.persistentFile(localName)
        .apply {
            mkdirs()
        }
    return ProfileManager(
        logTag,
        library,
        FileProfileRepository(logTag, directory)
    )
}

fun AppConfiguration.newTunnel(
    logTag: String,
    applicationContext: Context,
    requestVpnPermission: (Intent) -> Unit
): PartoutTunnel {
    return PartoutTunnel(
        logTag,
        applicationContext,
        PassepartoutVpnService::class.java,
        Tuning.TUNNEL_IS_FOREGROUND,
        requestVpnPermission
    )
}

fun AppConfiguration.newVersionChecker(
    logTag: String,
    userPreferencesObservable: UserPreferencesObservable
): VersionChecker {
    val changelogURL = constants.github::urlForChangelog
    val isCached = false
    val timeout = constants.url.timeoutInterval
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

fun newEventFlow(withReplay: Boolean = true): MutableSharedFlow<Event> {
    return MutableSharedFlow(
        replay = if (withReplay) Tuning.EVENT_REPLAY else 0,
        extraBufferCapacity = Tuning.EVENT_BUFFER_CAPACITY
    )
}
//endregion
