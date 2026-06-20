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
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.preferencesDataStoreFile
import com.algoritmico.passepartout.business.extensions.JSON
import com.algoritmico.passepartout.business.extensions.versionString
import com.algoritmico.passepartout.models.AppBundle
import com.algoritmico.passepartout.models.AppConstants
import com.algoritmico.passepartout.models.Credits
import com.algoritmico.passepartout.models.DistributionTarget
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import java.io.File

data class AndroidSystemInformation(
    val osLine: String,
    val deviceLine: String?
)

fun Context.appConstants(assets: AndroidConstants.Assets): AppConstants {
    val json = readAsset(assets.constantsFilename)
    return JSON.decode<AppConstants>(json)
}

fun Context.credits(assets: AndroidConstants.Assets): Credits {
    val json = readAsset(assets.creditsFilename)
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

fun Context.lastTunnelProfile(storage: AndroidConstants.Storage): File {
    return persistentFile(storage.tunnelProfileFilename)
}

fun Context.lastTunnelPreferences(storage: AndroidConstants.Storage): File {
    return persistentFile(storage.tunnelPreferencesFilename)
}

fun Context.userPreferencesStore(storage: AndroidConstants.Storage): DataStore<Preferences> {
    val appContext = applicationContext
    val key = "${appContext.packageName}:${storage.preferencesStoreName}"
    return synchronized(userPreferencesStores) {
        userPreferencesStores.getOrPut(key) {
            PreferenceDataStoreFactory.create(
                scope = CoroutineScope(Dispatchers.IO + SupervisorJob()),
                produceFile = {
                    appContext.preferencesDataStoreFile(storage.preferencesStoreName)
                }
            )
        }
    }
}

val Context.isBetaSuggestedByAndroidAPI: Boolean
    get() = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

fun Context.persistentFile(path: String): File {
    return File(filesDir, path)
}

private fun Context.readAsset(name: String): String {
    return assets.open(name).bufferedReader().use { it.readText() }
}

private val userPreferencesStores = mutableMapOf<String, DataStore<Preferences>>()
