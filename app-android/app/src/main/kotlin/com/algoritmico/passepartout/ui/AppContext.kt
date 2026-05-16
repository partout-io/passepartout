// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import android.content.Context
import android.content.Intent
import android.util.Log
import com.algoritmico.passepartout.abi.AppABIProfile
import com.algoritmico.passepartout.abi.AppABITunnel
import com.algoritmico.passepartout.abi.PassepartoutWrapper
import com.algoritmico.passepartout.abi.helpers.ABIEventDispatcher
import com.algoritmico.passepartout.abi.models.Event
import com.algoritmico.passepartout.readAsset
import com.algoritmico.passepartout.tunnel.PassepartoutVpnService
import io.partout.jni.PartoutTunnel
import io.partout.jni.PartoutVpnServiceRuntime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableSharedFlow
import java.io.Closeable
import java.io.File

class AppContext(
    context: Context,
    coroutineScope: CoroutineScope,
    tunnelChannel: PartoutVpnServiceRuntime.Channel,
    requestVpnPermission: (Intent) -> Unit
) : Closeable {
    private val applicationContext = context.applicationContext

    private val library = PassepartoutWrapper()

    private val tunnel = PartoutTunnel(
        applicationContext,
        PassepartoutVpnService::class.java,
        tunnelChannel,
        requestVpnPermission,
        coroutineScope
    )

    private val eventDispatcher: ABIEventDispatcher = ABIEventDispatcher

    private var eventSubscription: Closeable? = eventDispatcher.register(::handleEvent)

    private val appEvents = MutableSharedFlow<Event>(
        replay = APP_EVENT_REPLAY,
        extraBufferCapacity = APP_EVENT_BUFFER_CAPACITY
    )

    val profileObservable = ProfileObservable(
        AppABIProfile(library),
        appEvents,
        coroutineScope
    )

    val tunnelObservable = TunnelObservable(
        AppABITunnel(library),
        appEvents,
        coroutineScope
    )

    init {
        val partoutVersion = library.partoutVersion()
        Log.i("Passepartout", ">>> Partout $partoutVersion")
        Log.e("Passepartout", ">>> Started app")

        val bundle = applicationContext.readAsset(BUNDLE_FILENAME)
        val constants = applicationContext.readAsset(CONSTANTS_FILENAME)
        val profilesDirectory = File(applicationContext.noBackupFilesDir, PROFILES_DIRECTORY)
            .apply {
                mkdirs()
            }
        val cacheDirectory = applicationContext.cacheDir
        val code = library.appInit(
            bundle,
            constants,
            profilesDirectory.absolutePath,
            cacheDirectory.absolutePath,
            tunnel,
            eventDispatcher
        )
        if (code != 0) {
            close()
            throw RuntimeException("Unable to init app (code=$code)")
        }
    }

    fun onApplicationActive() {
        library.appOnForeground()
    }

    fun onVpnPermissionResult(isGranted: Boolean) {
        tunnel.onVpnPermissionResult(isGranted)
    }

    private fun handleEvent(event: Event) {
        Log.i("Passepartout", ">>> AppContext: $event")
        appEvents.tryEmit(event)
    }

    override fun close() {
        eventSubscription?.close()
        eventSubscription = null
        profileObservable.close()
        tunnelObservable.close()
        library.appDeinit { _, _ -> }
    }

    companion object {
        private const val APP_EVENT_BUFFER_CAPACITY = 64

        private const val APP_EVENT_REPLAY = 64

        private const val BUNDLE_FILENAME = "bundle.json"

        private const val CONSTANTS_FILENAME = "constants.json"

        private const val PROFILES_DIRECTORY = "profiles-v1"
    }
}
