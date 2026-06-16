// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import com.algoritmico.passepartout.PassepartoutVpnService
import com.algoritmico.passepartout.PassepartoutWrapper
import com.algoritmico.passepartout.extensions.Globals
import com.algoritmico.passepartout.extensions.appBundle
import com.algoritmico.passepartout.extensions.appConstants
import com.algoritmico.passepartout.extensions.isBetaSuggestedByAndroidAPI
import com.algoritmico.passepartout.extensions.newConfigManager
import com.algoritmico.passepartout.extensions.newProfileManager
import com.algoritmico.passepartout.extensions.newVersionChecker
import com.algoritmico.passepartout.models.AppConfiguration
import io.partout.PartoutTunnel
import kotlinx.coroutines.CoroutineScope
import java.io.Closeable
import java.io.File

class AppContext(
    logTag: String,
    context: Context,
    coroutineScope: CoroutineScope,
    requestVpnPermission: (Intent) -> Unit
) : Closeable {
    private val applicationContext = context.applicationContext
    private val library = PassepartoutWrapper()

    val profileObservable: ProfileObservable
    val tunnelObservable: TunnelObservable
    val userPreferencesObservable: UserPreferencesObservable
    val configObservable: ConfigObservable
    val versionObservable: VersionObservable
    val appConfiguration: AppConfiguration

    init {
        library.partoutInit()
        val partoutVersion = library.partoutVersion()
        Log.i(logTag, ">>> Partout $partoutVersion")

        Log.e(logTag, ">>> Started app")

        // User preferences
        userPreferencesObservable = UserPreferencesObservable(
            logTag,
            coroutineScope,
            applicationContext.userPreferencesStore
        )
        val preferences = userPreferencesObservable.currentPreferences
        Log.i(logTag, ">>> Preferences: $preferences")

        // Static app configuration
        val bundle = applicationContext.appBundle()
        Log.d(logTag, ">>> Bundle: $bundle")
        val constants = applicationContext.appConstants()
        Log.d(logTag, ">>> Constants: $bundle")
        appConfiguration = AppConfiguration(
            bundle = bundle,
            constants = constants
        )

        // Beta?
        val isBeta = context.isBetaSuggestedByAndroidAPI

        // Profiles
        // FIXME: ###, PROFILES_DIRECTORY
        val profilesDirectory = File(applicationContext.noBackupFilesDir, Globals.PROFILES_DIRECTORY)
            .apply {
                mkdirs()
            }
        val profileManager = appConfiguration.newProfileManager(
            logTag,
            library,
            directory = profilesDirectory
        )
        profileObservable = ProfileObservable(
            profileManager,
            coroutineScope
        )

        // Tunnel controller
        val tunnel = PartoutTunnel(
            logTag,
            applicationContext,
            PassepartoutVpnService::class.java,
            // FIXME: ###, TUNNEL_IS_FOREGROUND
            isForeground = Globals.TUNNEL_IS_FOREGROUND,
            requestVpnPermission
        )
        tunnelObservable = TunnelObservable(
            logTag,
            tunnel,
            userPreferencesObservable.preferences,
            coroutineScope
        )

        // Config flags
        val configManager = appConfiguration.newConfigManager(
            logTag,
            isBeta
        )
        configObservable = ConfigObservable(
            configManager,
            coroutineScope
        )

        // Version checker
        val versionChecker = appConfiguration.newVersionChecker(
            logTag,
            userPreferencesObservable
        )
        versionObservable = VersionObservable(
            versionChecker,
            coroutineScope
        )
    }

    fun onApplicationActive() {
        // FIXME: ###, LifecycleManager.onApplicationActive()
//        library.appOnForeground()
        configObservable.refresh()
        versionObservable.checkLatestRelease()
    }

    override fun close() {
        configObservable.close()
        profileObservable.close()
        tunnelObservable.close()
        userPreferencesObservable.close()
        versionObservable.close()
    }
}

private val Context.userPreferencesStore: DataStore<Preferences> by preferencesDataStore(
    // FIXME: ###, PREFERENCES_STORE_NAME
    Globals.PREFERENCES_STORE_NAME
)
