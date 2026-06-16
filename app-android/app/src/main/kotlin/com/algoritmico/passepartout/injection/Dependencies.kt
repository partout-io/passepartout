package com.algoritmico.passepartout.injection

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.compose.ui.platform.UriHandler
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import com.algoritmico.passepartout.PassepartoutVpnService
import com.algoritmico.passepartout.PassepartoutWrapper
import com.algoritmico.passepartout.extensions.betaConfigURL
import com.algoritmico.passepartout.extensions.configURL
import com.algoritmico.passepartout.extensions.urlForChangelog
import com.algoritmico.passepartout.managers.ConfigManager
import com.algoritmico.passepartout.managers.ProfileManager
import com.algoritmico.passepartout.managers.VersionChecker
import com.algoritmico.passepartout.models.AppBundle
import com.algoritmico.passepartout.models.AppConfiguration
import com.algoritmico.passepartout.models.AppConstants
import com.algoritmico.passepartout.models.Credits
import com.algoritmico.passepartout.models.DistributionTarget
import com.algoritmico.passepartout.models.Event
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.strategy.FileProfileRepository
import com.algoritmico.passepartout.strategy.GitHubConfigStrategy
import com.algoritmico.passepartout.strategy.GitHubReleaseStrategy
import com.algoritmico.passepartout.strategy.URLFetcher
import io.partout.PartoutTunnel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.encodeToJsonElement
import java.io.File

//region Constants
private object Globals {
    // Storage
    const val CONSTANTS_FILENAME = "constants.json"
    const val CREDITS_FILENAME = "credits.json"
    const val TUNNEL_PROFILE_FILENAME = "tunnel_profile.json"
    const val TUNNEL_PREFERENCES_FILENAME = "tunnel_preferences.json"
    const val PREFERENCES_STORE_NAME = "preferences"

    // Fine-tuning
    const val TUNNEL_IS_FOREGROUND = true
    const val EVENT_BUFFER_CAPACITY = 64
    const val EVENT_REPLAY = 64
}

object Tags {
    const val APP = "Passepartout"
    const val SERVICE = "PassepartoutVpnService"
    const val PARTOUT = "Partout"
    const val PARTOUT_JNI = "PartoutJNI"
}
//endregion

//region App configuration
fun Context.appConstants(): AppConstants {
    val json = applicationContext.readAsset(Globals.CONSTANTS_FILENAME)
    return JSON.decode<AppConstants>(json)
}

fun Context.appBundle(): AppBundle {
    // Manifest "application android:label" points to strings.xml "app_name"
    val appName = applicationInfo.loadLabel(packageManager).toString()
    // These come from "build.gradle.kts"
    val appInfo = packageInfo()
    val versionNumber = appInfo.versionName.orEmpty()
    val buildNumber = appInfo.longVersionCode
        .coerceAtMost(Int.MAX_VALUE.toLong())
        .toInt()

    return AppBundle(
        distributionTarget = DistributionTarget.appStore,
        displayName = appName,
        versionNumber = versionNumber,
        buildNumber = buildNumber,
        bundleStrings = emptyMap()
    )
}

fun Context.credits(): Credits {
    return JSON.decode<Credits>(readAsset(Globals.CREDITS_FILENAME))
}

private fun Context.packageInfo(): PackageInfo {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        packageManager.getPackageInfo(
            packageName,
            PackageManager.PackageInfoFlags.of(0)
        )
    } else {
        @Suppress("DEPRECATION")
        packageManager.getPackageInfo(packageName, 0)
    }
}

val Context.lastTunnelProfile: File
    get() = persistentFile(Globals.TUNNEL_PROFILE_FILENAME)

val Context.lastTunnelPreferences: File
    get() = persistentFile(Globals.TUNNEL_PREFERENCES_FILENAME)

val Context.userPreferencesStore: DataStore<Preferences> by preferencesDataStore(
    Globals.PREFERENCES_STORE_NAME
)

val Context.isBetaSuggestedByAndroidAPI: Boolean
    get() = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

fun UriHandler.safeOpenUri(uri: String) {
    runCatching {
        openUri(uri)
    }.onFailure {
        Log.e(Tags.APP, "Unable to open URL ($uri)", it)
    }
}

private fun Context.readAsset(name: String): String {
    return assets.open(name).bufferedReader().use { it.readText() }
}

private fun Context.persistentFile(path: String): File {
    return File(filesDir, path)
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
        Globals.TUNNEL_IS_FOREGROUND,
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
        replay = if (withReplay) Globals.EVENT_REPLAY else 0,
        extraBufferCapacity = Globals.EVENT_BUFFER_CAPACITY
    )
}
//endregion

//region JSON
object JSON {
    val _coder = Json {
        ignoreUnknownKeys = true
    }

    inline fun <reified T> encode(value: T): String {
        return _coder.encodeToString(value)
    }

    inline fun <reified T> encodeElement(value: T): JsonElement {
        return _coder.encodeToJsonElement(value)
    }

    inline fun <reified T> decode(json: String): T {
        return _coder.decodeFromString<T>(json)
    }
}