// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.app.Notification
import android.content.Intent
import android.net.VpnService
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.algoritmico.passepartout.abi.PassepartoutWrapper
import io.partout.jni.PartoutVpnServiceRuntime
import io.partout.jni.PartoutVpnServiceRuntime.Engine
import io.partout.jni.PartoutVpnServiceRuntime.Result
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class PassepartoutVpnService: VpnService() {
    private val runtime by lazy {
        PartoutVpnServiceRuntime(
            logTag = "Passepartout",
            service = this,
            channel = channel,
            engine = PassepartoutVpnEngine(
                library = PassepartoutWrapper(),
                bundleProvider = {
                    readAsset("bundle.json")
                },
                constantsProvider = {
                    readAsset("constants.json")
                },
                cachePathProvider = {
                    cacheDir.absolutePath
                }
            ),
            stopService = {
                stopSelf()
            }
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startServiceForeground()
        return runtime.onStartCommand(intent, flags, startId)
    }

    override fun onDestroy() {
        runtime.onDestroy()
        stopServiceForeground()
        super.onDestroy()
    }

    override fun onRevoke() {
        runtime.onRevoke()
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

    private suspend fun readAsset(name: String): String = withContext(Dispatchers.IO) {
        assets.open(name).bufferedReader().use { it.readText() }
    }

    companion object {
        private const val NOTIFICATION_ID = 1

        val channel = PartoutVpnServiceRuntime.Channel()
    }
}

private class PassepartoutVpnEngine(
    private val library: PassepartoutWrapper,
    private val bundleProvider: suspend () -> String,
    private val constantsProvider: suspend () -> String,
    private val cachePathProvider: () -> String
) : Engine {
    override suspend fun start(
        runtime: PartoutVpnServiceRuntime,
        profileJSON: String
    ): Result = withContext(Dispatchers.IO) {
        Result(
            library.tunnelStart(
                bundleProvider(),
                constantsProvider(),
                profileJSON,
                cachePathProvider(),
                runtime
            ),
            null
        )
    }

    override suspend fun stop(): Result = withContext(Dispatchers.IO) {
        val result = CompletableDeferred<Result>()
        library.tunnelStop { code, json ->
            result.complete(Result(code, json))
        }
        result.await()
    }
}
