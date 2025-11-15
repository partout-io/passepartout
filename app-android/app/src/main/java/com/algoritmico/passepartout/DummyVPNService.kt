package com.algoritmico.passepartout

import android.app.Notification
import android.content.Intent
import android.net.VpnService
import android.util.Log
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.algoritmico.partout.NativeLibraryWrapper
import com.algoritmico.partout.VpnWrapper

class DummyVPNService: VpnService() {
    private val library = NativeLibraryWrapper()
    private val vpnWrapper = VpnWrapper(this)
    private var ctx: Long? = null
    private var isRunning = false

    override fun onCreate() {
        super.onCreate()
        val cachePath = cacheDir.absolutePath
        Log.e("Passepartout", ">>> $cachePath")
        ctx = library.partoutInitialize(cachePath)
        logLibraryContext()
    }

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
        ctx?.let {
            library.partoutDeinitialize(it)
        }
        super.onDestroy()
    }

    private fun startVpn() {
        val notification = createNotification()
        startForeground(1, notification)

        // FIXME: read from intent
        val inputStream = assets.open("vps-tcp.ovpn")
//        val inputStream = assets.open("vps.json")
        val testProfileString = inputStream.bufferedReader().use { it.readText() }

        // FIXME: initialize inside NativeWrapper and never expose ctx
        ctx?.let {

            // FIXME: protect main socket from VPN to avoid circular
            // register daemon callback to report any new
            // descriptor (pp_socket or wg) in order to update the "protection list"
            // You need to call back into Kotlin and protect it before connecting
//            protect(fd)

            // FIXME: the daemon requires access to Builder as TunnelController
//                val builder = Builder()
//                    .setSession("MyVPN")
//                    .addAddress("10.0.0.2", 24) // Example VPN interface address
//                    .addDnsServer("8.8.8.8")
//                    .addRoute("0.0.0.0", 0) // Route all traffic
//                // FIXME: this is the interface to the tun device
//                val tun = builder.establish()
//            tun?.fd

            logLibraryContext()
            Log.e("Passepartout", ">>> Starting daemon")
            library.partoutDaemonStart(it, testProfileString, vpnWrapper)
            Log.e("Passepartout", ">>> Started daemon")
        }
        isRunning = true
    }

    private fun stopVpn() {
        if (!isRunning) { return }
        isRunning = false
        ctx?.let {
            logLibraryContext()
            Log.e("Passepartout", ">>> Stopping daemon")
            library.partoutDaemonStop(it)
            Log.e("Passepartout", ">>> Stopped daemon")
        }

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

    private fun logLibraryContext() {
        ctx?.let {
            Log.e("Passepartout", ">>> CTX = " + String.format("0x%016x", it))
        }
    }
}