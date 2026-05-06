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
import com.algoritmico.passepartout.helpers.ABIConnectionStatusDispatcher
import com.algoritmico.passepartout.helpers.NativeLibraryWrapper
import com.algoritmico.passepartout.helpers.globalJsonCoder
import io.partout.abi.ConnectionStatus
import io.partout.abi.TaggedProfile
import io.partout.jni.AndroidTunnelController
import io.partout.jni.AndroidTunnelStrategy
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.io.Closeable

class PassepartoutVPNService: VpnService() {
    private val library = NativeLibraryWrapper()
    private val vpnWrapper = AndroidTunnelController(this)
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val commandMutex = Mutex()
    private var statusSubscription: Closeable? = null
    private var profileId: String? = null
    private var isRunning = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startServiceForeground()
        if (intent?.action == AndroidTunnelStrategy.ACTION_STOP_VPN) {
            stopVpn()
            return START_NOT_STICKY;
        }
        val profileJSON = intent?.getStringExtra(AndroidTunnelStrategy.EXTRA_PROFILE_JSON)
        if (profileJSON.isNullOrBlank()) {
            Log.e("Passepartout", "Missing profile in VPN start intent")
            stopServiceForeground()
            stopSelf()
            return START_NOT_STICKY
        }
        startVpn(profileJSON)
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
        serviceScope.launch {
            commandMutex.withLock {
                stopCurrentTunnel()
                startCurrentTunnel(profileJSON)
            }
        }
    }

    private fun stopVpn() {
        serviceScope.launch {
            commandMutex.withLock {
                stopCurrentTunnel()
                stopServiceForeground()
                stopSelf()
            }
        }
    }

    private suspend fun startCurrentTunnel(profileJSON: String) {
        profileId = runCatching {
            globalJsonCoder.decodeFromString<TaggedProfile>(profileJSON).id
        }.getOrNull()
        isRunning = true
        activeProfileId = profileId

        val bundle = readAsset("bundle.json")
        val constants = readAsset("constants.json")
        val cachePath = cacheDir.absolutePath
        Log.e("Passepartout", ">>> Starting daemon (cache: $cachePath)")

        statusSubscription?.close()
        statusSubscription = ABIConnectionStatusDispatcher.register(::handleStatus)

        val result = awaitTunnelStart(
            bundle = bundle,
            constants = constants,
            profileJSON = profileJSON,
            cachePath = cachePath
        )
        if (result.code == 0) {
            Log.e("Passepartout", ">>> Started daemon")
        } else {
            Log.e("Passepartout", "Unable to start daemon (code=${result.code}): ${result.json}")
            val failedProfileId = profileId
            stopServiceForeground()
            stopSelf()
            isRunning = false
            activeProfileId = null
            reportStatus(ConnectionStatus.disconnected, failedProfileId)
            profileId = null
            releaseTunnelReferences()
        }
    }

    private suspend fun stopCurrentTunnel() {
        if (!isRunning) { return }

        Log.e("Passepartout", ">>> Stopping daemon")
        val stoppedProfileId = profileId
        val result = awaitTunnelStop()
        if (result.code == 0) {
            Log.e("Passepartout", ">>> Stopped daemon")
        } else {
            Log.e("Passepartout", "Unable to stop daemon (code=${result.code}): ${result.json}")
        }
        isRunning = false
        activeProfileId = null
        reportStatus(ConnectionStatus.disconnected, stoppedProfileId)
        profileId = null
        releaseTunnelReferences()
    }

    private suspend fun awaitTunnelStart(
        bundle: String,
        constants: String,
        profileJSON: String,
        cachePath: String
    ): ABIResult = withContext(Dispatchers.IO) {
        val result = CompletableDeferred<ABIResult>()
        library.tunnelStart(
            bundle,
            constants,
            profileJSON,
            cachePath,
            ABIConnectionStatusDispatcher,
            vpnWrapper
        ) { code, json ->
            result.complete(ABIResult(code, json))
        }
        result.await()
    }

    private suspend fun awaitTunnelStop(): ABIResult = withContext(Dispatchers.IO) {
        val result = CompletableDeferred<ABIResult>()
        library.tunnelStop { code, json ->
            result.complete(ABIResult(code, json))
        }
        result.await()
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

    private fun reportStatus(status: ConnectionStatus, profileId: String? = this.profileId) {
        val profileId = profileId ?: return
        val json = globalJsonCoder.encodeToString(
            OnConnectionStatus(
                profileId = profileId,
                status = status
            )
        )
        ABIConnectionStatusDispatcher.onStatus(json)
    }

    private suspend fun readAsset(name: String): String = withContext(Dispatchers.IO) {
        assets.open(name).bufferedReader().use { it.readText() }
    }

    private fun startServiceForeground() {
        startForeground(NOTIFICATION_ID, createNotification())
    }

    private fun stopServiceForeground() {
        stopForeground(STOP_FOREGROUND_REMOVE)
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

    companion object {
        private const val NOTIFICATION_ID = 1

        @Volatile
        private var activeProfileId: String? = null

        fun isActive(profileId: String): Boolean {
            return activeProfileId == profileId
        }
    }
}

private data class ABIResult(
    val code: Int,
    val json: String?
)
