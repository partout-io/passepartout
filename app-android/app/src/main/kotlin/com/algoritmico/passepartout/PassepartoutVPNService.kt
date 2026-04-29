// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.app.Notification
import android.content.Intent
import android.net.VpnService
import android.util.Log
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.algoritmico.passepartout.abi.OnConnectionStatus
import com.algoritmico.passepartout.helpers.ABIStatusDispatcher
import com.algoritmico.passepartout.helpers.NativeLibraryWrapper
import io.partout.jni.AndroidTunnelController
import io.partout.jni.AndroidTunnelStrategy
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.Closeable

class PassepartoutVPNService: VpnService() {
    private val library = NativeLibraryWrapper()
    private val vpnWrapper = AndroidTunnelController(this)
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var startJob: Job? = null
    private var stopJob: Job? = null
    private var statusSubscription: Closeable? = null
    private var isRunning = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == AndroidTunnelStrategy.ACTION_STOP_VPN) {
            stopVpn()
            return START_NOT_STICKY;
        }
        val profileJSON = intent?.getStringExtra(AndroidTunnelStrategy.EXTRA_PROFILE_JSON)
        if (profileJSON.isNullOrBlank()) {
            Log.e("Passepartout", "Missing profile in VPN start intent")
            return START_NOT_STICKY
        }
        if (!isRunning) {
            startVpn(profileJSON)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        if (isRunning) {
            stopVpn()
        } else {
            statusSubscription?.close()
            statusSubscription = null
            serviceScope.cancel()
        }
        super.onDestroy()
    }

    private fun startVpn(profileJSON: String) {
        if (isRunning) { return }
        val notification = createNotification()
        startForeground(1, notification)
        isRunning = true

        startJob?.cancel()
        startJob = serviceScope.launch {
            val bundle = readAsset("bundle.json")
            val constants = readAsset("constants.json")

            val cachePath = cacheDir.absolutePath
            Log.e("Passepartout", ">>> Starting daemon (cache: $cachePath)")
            statusSubscription?.close()
            statusSubscription = ABIStatusDispatcher.register(::handleStatus)
            withContext(Dispatchers.IO) {
                library.tunnelStart(
                    bundle,
                    constants,
                    profileJSON,
                    cachePath,
                    ABIStatusDispatcher,
                    vpnWrapper
                ) { code, json ->
                    serviceScope.launch {
                        if (code == 0) {
                            Log.e("Passepartout", ">>> Started daemon")
                        } else {
                            Log.e("Passepartout", "Unable to start daemon (code=$code): $json")
                            stopForeground(STOP_FOREGROUND_REMOVE)
                            stopSelf()
                            isRunning = false
                            releaseTunnelReferences()
                        }
                    }
                }
            }
        }
    }

    private fun stopVpn() {
        if (!isRunning) { return }

        stopJob?.cancel()
        stopJob = serviceScope.launch {
            Log.e("Passepartout", ">>> Stopping daemon")
            withContext(Dispatchers.IO) {
                library.tunnelStop { code, json ->
                    serviceScope.launch {
                        if (code == 0) {
                            Log.e("Passepartout", ">>> Stopped daemon")
                        } else {
                            Log.e("Passepartout", "Unable to stop daemon (code=$code): $json")
                        }
                        stopForeground(STOP_FOREGROUND_REMOVE)
                        stopSelf()
                        isRunning = false
                        releaseTunnelReferences()
                        serviceScope.cancel()
                    }
                }
            }
        }
    }

    private fun releaseTunnelReferences() {
        statusSubscription?.close()
        statusSubscription = null
        library.tunnelRelease()
    }

    private fun handleStatus(onStatusJSON: String) {
        val onStatus = globalJsonCoder.decodeFromString<OnConnectionStatus>(onStatusJSON)
        Log.i("Passepartout", ">>> onStatus = ${onStatus}")
    }

    private suspend fun readAsset(name: String): String = withContext(Dispatchers.IO) {
        assets.open(name).bufferedReader().use { it.readText() }
    }

    private fun createNotification(): Notification {
        val channelId = "vpn_service_channel"

        // Create a notification channel (required on Android 8.0+)
        val channel = NotificationChannelCompat.Builder(
            channelId,
            NotificationManagerCompat.IMPORTANCE_LOW // low importance to avoid sound
        )
            .setName("Passepartout VPN")
            .setDescription("Notification for the VPN foreground service")
            .build()

        NotificationManagerCompat
            .from(this)
            .createNotificationChannel(channel)

        // Build the notification
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Passepartout Active")
            .setContentText("VPN is running")
            .setOngoing(true)
            .build()
    }
}
