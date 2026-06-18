// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.context

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import com.algoritmico.passepartout.business.extensions.JSON
import com.algoritmico.passepartout.business.extensions.versionString
import com.algoritmico.passepartout.models.AppBundle
import com.algoritmico.passepartout.models.AppConstants
import com.algoritmico.passepartout.models.Credits
import com.algoritmico.passepartout.models.DistributionTarget
import java.io.File

private object Storage {
    const val CONSTANTS_FILENAME = "constants.json"
    const val CREDITS_FILENAME = "credits.json"
    const val TUNNEL_PROFILE_FILENAME = "tunnel_profile.json"
    const val TUNNEL_PREFERENCES_FILENAME = "tunnel_preferences.json"
    const val PREFERENCES_STORE_NAME = "preferences"
}

data class AndroidSystemInformation(
    val osLine: String,
    val deviceLine: String?
)

fun Context.appConstants(): AppConstants {
    val json = readAsset(Storage.CONSTANTS_FILENAME)
    return JSON.decode<AppConstants>(json)
}

fun Context.credits(): Credits {
    val json = readAsset(Storage.CREDITS_FILENAME)
    return JSON.decode<Credits>(json)
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

fun Context.logPreamble(logTag: String) {
    val bundle = appBundle()
    val systemInformation = androidSystemInformation()
    AppLog.i(logTag, "")
    AppLog.i(logTag, "--- BEGIN ---")
    AppLog.i(logTag, "")
    AppLog.i(logTag, "App: ${bundle.versionString}")
    AppLog.i(logTag, "OS: ${systemInformation.osLine}")
    systemInformation.deviceLine?.let {
        AppLog.i(logTag, "Device: $it")
    }
    AppLog.i(logTag, "")
}

fun Context.androidSystemInformation(): AndroidSystemInformation {
    return AndroidSystemInformation(
        osLine = androidOsString,
        deviceLine = androidDeviceString
    )
}

private val Context.androidOsString: String
    get() {
        val version = Build.VERSION.RELEASE
            .takeIf { it.isNotBlank() }
            ?: "API ${Build.VERSION.SDK_INT}"
        return "Android $version"
    }

private val Context.androidDeviceString: String?
    get() {
        val manufacturer = Build.MANUFACTURER.trim()
        val model = Build.MODEL.trim()
        return when {
            manufacturer.isBlank() && model.isBlank() -> null
            manufacturer.isBlank() -> model
            model.isBlank() -> manufacturer
            model.startsWith(manufacturer, ignoreCase = true) -> model
            else -> "$manufacturer $model"
        }
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
    get() = persistentFile(Storage.TUNNEL_PROFILE_FILENAME)

val Context.lastTunnelPreferences: File
    get() = persistentFile(Storage.TUNNEL_PREFERENCES_FILENAME)

val Context.userPreferencesStore: DataStore<Preferences> by preferencesDataStore(
    Storage.PREFERENCES_STORE_NAME
)

val Context.isBetaSuggestedByAndroidAPI: Boolean
    get() = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

fun Context.persistentFile(path: String): File {
    return File(filesDir, path)
}

private fun Context.readAsset(name: String): String {
    return assets.open(name).bufferedReader().use { it.readText() }
}
