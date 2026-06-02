// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import com.algoritmico.passepartout.abi.models.AppBundle
import com.algoritmico.passepartout.abi.models.DistributionTarget
import kotlinx.serialization.json.Json

object Globals {
    val json = Json {
        ignoreUnknownKeys = true
    }

    const val TAG_APP = "Passepartout"
    const val TAG_SERVICE = "PassepartoutVpnService"
    const val TAG_JNI = "PassepartoutJNI"

    const val CONSTANTS_FILENAME = "constants.json"
    const val PROFILES_DIRECTORY = "profiles-v1"
    const val PREFERENCES_STORE_NAME = "preferences"

    const val TUNNEL_IS_FOREGROUND = true
    const val TUNNEL_PROFILE_LAST_PATH = "tunnel_profile.json"
    const val TUNNEL_PREFERENCES_LAST_PATH = "tunnel_preferences.json"

    const val EVENT_BUFFER_CAPACITY = 64
    const val EVENT_REPLAY = 64
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

fun Context.appBundleJSON(): String = Globals.json.encodeToString(appBundle())

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

fun Context.readAsset(name: String): String {
    return assets.open(name).bufferedReader().use { it.readText() }
}
