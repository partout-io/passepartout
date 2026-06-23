// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.content.Intent
import android.net.VpnService
import android.os.IBinder
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.context.appBundle
import com.algoritmico.passepartout.context.defaultAndroidConstants
import com.algoritmico.passepartout.context.logPreamble
import com.algoritmico.passepartout.vpn.VpnServiceNotificationController
import com.algoritmico.passepartout.vpn.VpnServiceStore
import io.partout.NativeTunnelControllerJNI
import io.partout.PartoutVpnServiceRuntime
import io.partout.abi.PartoutException
import io.partout.models.TunnelSnapshot
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

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
            engine = engine,
            logsSnapshots = logsSnapshots
        )
    }

    private val engine = object : PartoutVpnServiceRuntime.Engine {
        private val library = PassepartoutWrapper()

        override suspend fun start(
            intent: Intent?,
            controller: NativeTunnelControllerJNI,
            profileJSON: String
        ) = withContext(Dispatchers.IO) {
            applicationContext.logPreamble(logTag)

            AppLog.i(logTag, "Started service")
            val partoutVersion = library.partoutVersion()
            AppLog.i(logTag, "Partout $partoutVersion")

            val bundle = applicationContext.appBundle()
            AppLog.d(logTag, "Bundle: $bundle")
            notifications.updateProfileName(profileJSON)

            // Try preferences from intent, otherwise load last persisted
            val preferences = store.readPreferences(
                intent?.getStringExtra(EXTRA_TUNNEL_PREFERENCES)
            )
            AppLog.i(logTag, "Preferences: $preferences")

            // Initialize the library with the intent preferences
//            val openvpn_version = preferences?.configFlags ? 3 : 2
            val logsPrivateData = preferences?.logsPrivateData ?: false
            library.partoutInit(androidConstants.tags.servicePartout, logsPrivateData)

            // This call retains the controller strongly
            val dnsFallsBack = preferences?.dnsFallsBack ?: true
            val code = library.partoutDaemonStart(
                profileJSON,
                cacheDir.absolutePath,
                controller,
                dnsFallsBack,
                logsSnapshots,
                0L
            )
            if (code != 0) {
                throw PartoutException(code, null)
            }
        }

        override suspend fun stop() = withContext(Dispatchers.IO) {
            suspendCancellableCoroutine { continuation ->
                library.partoutDaemonStop { code, payload ->
                    if (code != 0) {
                        continuation.resumeWithException(PartoutException(code, payload))
                        return@partoutDaemonStop
                    }
                    continuation.resume(Unit)
                }
            }
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
    }
}
