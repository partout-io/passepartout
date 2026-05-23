// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import android.content.Context
import android.content.Intent
import android.util.Log
import com.algoritmico.passepartout.Globals
import com.algoritmico.passepartout.PassepartoutVpnService
import com.algoritmico.passepartout.abi.AppABIProfile
import com.algoritmico.passepartout.abi.PassepartoutWrapper
import com.algoritmico.passepartout.abi.helpers.ABIEventDispatcher
import com.algoritmico.passepartout.abi.helpers.ABIURLFetcher
import com.algoritmico.passepartout.abi.models.Event
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

    init {
        val partoutVersion = library.partoutVersion()
        Log.i(Globals.logTag, ">>> Partout $partoutVersion")
        Log.e(Globals.logTag, ">>> Started app")

        val bundle = applicationContext.readAsset(Globals.BUNDLE_FILENAME)
        val constants = applicationContext.readAsset(Globals.CONSTANTS_FILENAME)
        val profilesDirectory = File(applicationContext.noBackupFilesDir, Globals.PROFILES_DIRECTORY)
            .apply {
                mkdirs()
            }
        val cacheDirectory = applicationContext.cacheDir
        val code = library.appInit(
            bundle,
            constants,
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
            AppABIProfile(library),
            appEvents,
            coroutineScope
        )
        val tunnel = PartoutTunnel(
            Globals.logTag,
            applicationContext,
            PassepartoutVpnService::class.java,
            isForeground = false,
            requestVpnPermission
        )
        tunnelObservable = TunnelObservable(
            Globals.logTag,
            tunnel,
            appEvents,
            coroutineScope
        )
    }

    fun onApplicationActive() {
        library.appOnForeground()
    }

    private fun handleEvent(event: Event) {
        Log.i(Globals.logTag, ">>> AppContext: $event")
        appEvents.tryEmit(event)
    }

    override fun close() {
        eventSubscription?.close()
        eventSubscription = null
        profileObservable.close()
        tunnelObservable.close()
        library.appDeinit { _, _ -> }
    }
}
