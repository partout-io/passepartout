// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.content.Intent
import android.net.VpnService
import android.os.IBinder
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.context.appBundle
import com.algoritmico.passepartout.context.appConstants
import com.algoritmico.passepartout.context.defaultAndroidConstants
import com.algoritmico.passepartout.context.logPreamble
import com.algoritmico.passepartout.vpn.VpnServiceNotificationController
import com.algoritmico.passepartout.vpn.VpnServiceStore
import io.partout.PartoutVpnServiceRuntime
import io.partout.models.CryptoBackend
import io.partout.models.TunnelControllerOptions
import io.partout.models.TunnelSnapshot

class PassepartoutVpnService: VpnService() {
    private val androidConstants = defaultAndroidConstants
    private val logTag = androidConstants.tags.service
    private val jniLogTag = androidConstants.tags.partoutJni
    private val logsSnapshots = androidConstants.tunnel.logsSnapshots

    private val store by lazy {
        VpnServiceStore(
            logTag = logTag,
            context = applicationContext,
            storage = androidConstants.storage
        )
    }

    private val notifications by lazy {
        VpnServiceNotificationController(
            logTag = logTag,
            service = this,
            serviceClass = PassepartoutVpnService::class.java,
            logsSnapshots = logsSnapshots
        )
    }

    private val runtime by lazy {
        PartoutVpnServiceRuntime(
            logTag = logTag,
            jniLogTag = jniLogTag,
            service = this,
            wrapper = androidConstants.newWrapper(),
            engine = engine
        )
    }

    private val engine = object : PartoutVpnServiceRuntime.Engine {
        override suspend fun prepareStart(
            version: String,
            intent: Intent?,
            profileJSON: String
        ): PartoutVpnServiceRuntime.StartOptions {
            applicationContext.logPreamble(logTag)

            AppLog.i(logTag, "Started service")
            AppLog.i(logTag, "Partout $version")

            val bundle = applicationContext.appBundle()
            AppLog.d(logTag, "Bundle: $bundle")
            notifications.updateProfileName(profileJSON)

            // Try constant min delta
            val minDataCountDelta = runCatchingNonFatal {
                val constants = applicationContext.appConstants(androidConstants.assets)
                constants.tunnel.minDataCountDelta ?: 0L
            }.getOrElse {
                AppLog.w(logTag, "Unable to load tunnel constants, using defaults", it)
                DEFAULT_MIN_DATA_COUNT_DELTA
            }

            // Try preferences from intent, otherwise load last persisted
            val preferences = store.readPreferences(
                intent?.getStringExtra(EXTRA_TUNNEL_PREFERENCES)
            )
            AppLog.i(logTag, "Preferences: $preferences")

            // Initialize the library with the intent preferences
//            val openvpn_version = preferences?.configFlags ? 3 : 2
            val logsPrivateData = preferences?.logsPrivateData ?: false

            // XXX: Hardcode CloudFlare for now
            val dnsFallsBack = preferences?.dnsFallsBack ?: true
            val dnsFallbackServers = if (dnsFallsBack) listOf("1.1.1.1", "1.0.0.1") else emptyList()

            val controllerOptions = TunnelControllerOptions(
                dnsFallbackServers,
                logsSnapshots
            )
            val cryptoBackend = CryptoBackend.decode(preferences?.cryptoBackend)
            AppLog.d(logTag, "Crypto backend: $cryptoBackend")
            return PartoutVpnServiceRuntime.StartOptions(
                logsPrivateData,
                minDataCountDelta,
                cryptoBackend ?: CryptoBackend.openssl,
                controllerOptions
            )
        }

        override suspend fun readLastProfile(): String {
            return store.readLastProfile()
        }

        override suspend fun writeLastProfile(json: String) {
            store.writeLastProfile(json)
        }

        override suspend fun deleteLastProfile(id: String) {
            store.deleteLastProfile(id)
        }

        override fun onSnapshot(snapshot: TunnelSnapshot) {
            notifications.update(snapshot)
        }

        override fun onServiceStopped(wasRevoked: Boolean) {
            notifications.onServiceStopped(wasRevoked)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == PartoutVpnServiceRuntime.ACTION_STOP_VPN) {
            return runtime.onStartCommand(intent, flags, startId)
        }
        notifications.prepareStart(
            intent?.getStringExtra(PartoutVpnServiceRuntime.EXTRA_PROFILE_JSON)
        )
        try {
            notifications.startForeground()
        } catch (it: SecurityException) {
            AppLog.e(logTag, "Unable to start service in foreground", it)
            return START_NOT_STICKY
        } catch (it: RuntimeException) {
            AppLog.e(logTag, "Unable to start service in foreground", it)
            return START_NOT_STICKY
        }
        if (prepare(applicationContext) != null) {
            AppLog.w(logTag, "VPN permission was revoked before start")
            runtime.onRevoke()
            return START_NOT_STICKY
        }
        return runtime.onStartCommand(intent, flags, startId)
    }

    override fun onDestroy() {
        notifications.onDestroy()
        runtime.onDestroy()
        super.onDestroy()
    }

    override fun onRevoke() {
        runtime.onRevoke()
    }

    override fun onBind(intent: Intent?): IBinder? {
        if (intent?.action == SERVICE_INTERFACE) {
            return super.onBind(intent)
        }
        return runtime.onBind(intent)
    }

    companion object {
        const val EXTRA_TUNNEL_PREFERENCES = "com.algoritmico.passepartout.extra.TUNNEL_PREFERENCES"
        private const val DEFAULT_MIN_DATA_COUNT_DELTA = 1024L
    }
}
