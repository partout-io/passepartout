package com.algoritmico.passepartout

import android.app.Notification
import android.content.Intent
import android.net.VpnService
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.algoritmico.passepartout.abi.PassepartoutWrapper
import io.partout.PartoutVpnServiceRuntime
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class PassepartoutVpnService: VpnService() {
    private val runtime by lazy {
        PartoutVpnServiceRuntime(
            logTag = Globals.serviceLogTag,
            service = this,
            engine = VpnEngine(
                library = PassepartoutWrapper(),
                bundleProvider = {
                    readAsset(BUNDLE_FILENAME)
                },
                constantsProvider = {
                    readAsset(CONSTANTS_FILENAME)
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
        startForeground(NOTIFICATION_ID, createNotification())
        return runtime.onStartCommand(intent, flags, startId)
    }

    override fun onDestroy() {
        runtime.onDestroy()
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    override fun onRevoke() {
        runtime.onRevoke()
    }

    private fun createNotification(): Notification {
        val channelId = NOTIFICATION_CHANNEL_ID

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

    private class VpnEngine(
        private val library: PassepartoutWrapper,
        private val bundleProvider: suspend () -> String,
        private val constantsProvider: suspend () -> String,
        private val cachePathProvider: () -> String
    ) : PartoutVpnServiceRuntime.Engine {
        override suspend fun start(
            runtime: PartoutVpnServiceRuntime,
            profileJSON: String
        ): PartoutVpnServiceRuntime.Result = withContext(Dispatchers.IO) {
            PartoutVpnServiceRuntime.Result(
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

        override suspend fun stop(): PartoutVpnServiceRuntime.Result = withContext(Dispatchers.IO) {
            val result = CompletableDeferred<PartoutVpnServiceRuntime.Result>()
            library.tunnelStop { code, json ->
                result.complete(PartoutVpnServiceRuntime.Result(code, json))
            }
            result.await()
        }
    }

    companion object {
        private const val BUNDLE_FILENAME = "bundle.json"

        private const val CONSTANTS_FILENAME = "constants.json"

        private const val NOTIFICATION_ID = 1

        private const val NOTIFICATION_CHANNEL_ID = "vpn_service_channel"
    }
}