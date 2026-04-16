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
import com.algoritmico.passepartout.helpers.NativeLibraryWrapper
import io.partout.jni.AndroidTunnelController

class DummyVPNService: VpnService() {
    private val library = NativeLibraryWrapper()
    private val vpnWrapper = AndroidTunnelController(this)
    private var isRunning = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP_VPN") {
            stopVpn()
            return START_NOT_STICKY;
        }
        if (!isRunning) {
            startVpn()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }

    private fun startVpn() {
        val notification = createNotification()
        startForeground(1, notification)

        var bundle = String(assets.open("bundle.json").readBytes())
        var constants = String(assets.open("constants.json").readBytes())
        // FIXME: read profile from intent
        val testProfile = String(assets.open("vps.conf").readBytes())
//        val testProfile = String(assets.open("vps-tcp.ovpn").readBytes())

        val cachePath = cacheDir.absolutePath
        Log.e("Passepartout", ">>> Starting daemon (cache: $cachePath)")
        library.tunnelStart(
            bundle,
            constants,
            testProfile,
            cachePath,
            vpnWrapper
        )
        Log.e("Passepartout", ">>> Started daemon")

        isRunning = true
    }

    private fun stopVpn() {
        if (!isRunning) { return }
        isRunning = false
        Log.e("Passepartout", ">>> Stopping daemon")
        library.tunnelStop()
        Log.e("Passepartout", ">>> Stopped daemon")

        // FIXME: add callback to partout_daemon_start and partout_daemon_stop
        Thread.sleep(3000)

        // FIXME: Always close the ParcelFileDescriptor to release the TUN interface.
        // FIXME: Always stop your native VPN library to free resources.
        // FIXME: Call stopForeground(true) + stopSelf() to terminate the service cleanly.
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
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