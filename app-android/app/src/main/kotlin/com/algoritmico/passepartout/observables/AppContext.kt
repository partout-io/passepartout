// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.content.Context
import android.content.Intent
import android.util.Log
import com.algoritmico.passepartout.Globals
import com.algoritmico.passepartout.PassepartoutVpnService
import com.algoritmico.passepartout.abi.AppABIKeyStore
import com.algoritmico.passepartout.abi.AppABIProfile
import com.algoritmico.passepartout.abi.PassepartoutWrapper
import com.algoritmico.passepartout.abi.helpers.ABIEventDispatcher
import com.algoritmico.passepartout.abi.helpers.ABIURLFetcher
import com.algoritmico.passepartout.abi.models.Event
import com.algoritmico.passepartout.appBundleJSON
import com.algoritmico.passepartout.readAsset
import io.partout.PartoutTunnel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableSharedFlow
import java.io.Closeable
import java.io.File

class AppContext(
    context: Context,
    coroutineScope: CoroutineScope,
    requestVpnPermission: (Intent) -> Unit
) : Closeable {
    private val applicationContext = context.applicationContext
    private val library = PassepartoutWrapper()
    private val eventDispatcher: ABIEventDispatcher = ABIEventDispatcher
    private var eventSubscription: Closeable? = eventDispatcher.register(::handleEvent)

    private val appEvents = MutableSharedFlow<Event>(
        replay = Globals.EVENT_REPLAY,
        extraBufferCapacity = Globals.EVENT_BUFFER_CAPACITY
    )

    val profileObservable: ProfileObservable
    val tunnelObservable: TunnelObservable
    val userPreferencesObservable: UserPreferencesObservable

    init {
        val partoutVersion = library.partoutVersion()
        Log.i(Globals.TAG_APP, ">>> Partout $partoutVersion")
        Log.e(Globals.TAG_APP, ">>> Started app")

        userPreferencesObservable = UserPreferencesObservable(
            Globals.TAG_APP,
            AppABIKeyStore(library),
            appEvents,
            coroutineScope,
            context
        )
        val preferences = userPreferencesObservable.preferencesJSON()
        Log.i(Globals.TAG_APP, ">>> Preferences: $preferences")

        val bundle = applicationContext.appBundleJSON()
        Log.e(Globals.TAG_APP, ">>> Bundle: $bundle")

        val constants = applicationContext.readAsset(Globals.CONSTANTS_FILENAME)
        val profilesDirectory = File(applicationContext.noBackupFilesDir, Globals.PROFILES_DIRECTORY)
            .apply {
                mkdirs()
            }
        val cacheDirectory = applicationContext.cacheDir
        val code = library.appInit(
            bundle,
            constants,
            preferences,
            profilesDirectory.absolutePath,
            cacheDirectory.absolutePath,
            ABIURLFetcher,
            eventDispatcher
        )
        if (code != 0) {
            close()
            throw RuntimeException("Unable to init app (code=$code)")
        }

        profileObservable = ProfileObservable(
            Globals.TAG_APP,
            AppABIProfile(library),
            appEvents,
            coroutineScope
        )
        val tunnel = PartoutTunnel(
            Globals.TAG_APP,
            applicationContext,
            PassepartoutVpnService::class.java,
            isForeground = Globals.TUNNEL_IS_FOREGROUND,
            requestVpnPermission
        )
        tunnelObservable = TunnelObservable(
            Globals.TAG_APP,
            tunnel,
            appEvents,
            userPreferencesObservable.preferences,
            coroutineScope
        )
    }

    fun onApplicationActive() {
        library.appOnForeground()
    }

    private fun handleEvent(event: Event) {
        Log.i(Globals.TAG_APP, ">>> AppContext: $event")
        appEvents.tryEmit(event)
    }

    override fun close() {
        eventSubscription?.close()
        eventSubscription = null
        userPreferencesObservable.close()
        profileObservable.close()
        tunnelObservable.close()
        library.appDeinit { _, _ -> }
    }
}
