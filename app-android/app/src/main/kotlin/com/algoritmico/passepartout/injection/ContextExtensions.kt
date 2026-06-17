// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.injection

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
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
