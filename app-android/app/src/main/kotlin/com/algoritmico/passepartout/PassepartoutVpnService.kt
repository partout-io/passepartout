package com.algoritmico.passepartout

import android.app.Notification
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.IBinder
import android.util.AtomicFile
import android.util.Log
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import com.algoritmico.passepartout.abi.PassepartoutWrapper
import com.algoritmico.passepartout.abi.helpers.ABIException
import io.partout.PartoutVpnServiceRuntime
import io.partout.models.TunnelSnapshot
import io.partout.vpn.JNITunnelController
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class PassepartoutVpnService: VpnService() {
    private val runtime by lazy {
        PartoutVpnServiceRuntime(
            logTag = Globals.TAG_SERVICE,
            jniLogTag = Globals.TAG_JNI,
            service = this,
            engine = engine
        )
    }

    private val engine = object : PartoutVpnServiceRuntime.Engine {
        private val logTag = Globals.TAG_SERVICE
        private val library = PassepartoutWrapper()
        private val lastPreferencesFile: File
            get() = File(noBackupFilesDir, Globals.TUNNEL_PREFERENCES_LAST_PATH)
        private val lastProfileFile: File
            get() = File(noBackupFilesDir, Globals.TUNNEL_PROFILE_LAST_PATH)

        override suspend fun start(
            intent: Intent?,
            controller: JNITunnelController,
            profileJSON: String
        ) = withContext(Dispatchers.IO) {
            val bundle = appBundleJSON()
            Log.e(logTag, ">>> Bundle: $bundle")

            // Try preferences from intent, otherwise load last persisted
            val intentPreferencesJSON = intent?.getStringExtra(EXTRA_TUNNEL_PREFERENCES)
            val preferencesJSON = if (intentPreferencesJSON.isNullOrBlank()) {
                Log.i(logTag, "Load last preferences")
                readLastPreferences()
            } else {
                Log.i(logTag, "Load and persist start preferences")
                writeLastPreferences(intentPreferencesJSON)
                intentPreferencesJSON
            }

            // This call retains the controller strongly
            val code = library.tunnelStart(
                bundle,
                readAsset(Globals.CONSTANTS_FILENAME),
                preferencesJSON,
                profileJSON,
                cacheDir.absolutePath,
                controller
            )
            if (code != 0) {
                throw ABIException(code, null)
            }
        }

        override suspend fun stop() = withContext(Dispatchers.IO) {
            val result = CompletableDeferred<Unit>()
            library.tunnelStop { code, _ ->
                if (code != 0) {
                    result.completeExceptionally(ABIException(code, null))
                    return@tunnelStop
                }
                result.complete(Unit)
            }
            result.await()
        }

        override suspend fun readLastProfile(): String {
            return withContext(Dispatchers.IO) {
                readLastFile(lastProfileFile)
            }
        }

        override suspend fun writeLastProfile(json: String) {
            withContext(Dispatchers.IO) {
                writeLastFile(lastProfileFile, json)
            }
        }

        override fun onSnapshot(snapshot: TunnelSnapshot) {
            updateNotification(snapshot)
        }

        private fun readLastPreferences(): String? {
            return runCatching {
                readLastFile(lastPreferencesFile)
            }.onFailure {
                Log.w(Globals.TAG_SERVICE, "Unable to read last tunnel preferences", it)
            }.getOrNull()
        }

        private fun writeLastPreferences(json: String) {
            writeLastFile(lastPreferencesFile, json)
        }

        private fun readLastFile(file: File): String {
            return AtomicFile(file).openRead().bufferedReader(Charsets.UTF_8).use {
                it.readText()
            }
        }

        private fun writeLastFile(file: File, json: String) {
            val atomicFile = AtomicFile(file)
            val stream = atomicFile.startWrite()
            try {
                stream.write(json.toByteArray(Charsets.UTF_8))
                atomicFile.finishWrite(stream)
            } catch (e: Exception) {
                atomicFile.failWrite(stream)
                throw e
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ServiceCompat.startForeground(
            this,
            VPN_NOTIFICATION_ID,
            createNotification(),
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED
        )
        return runtime.onStartCommand(intent, flags, startId)
    }

    override fun onDestroy() {
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
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

    private fun createNotification(): Notification {
        val channelId = VPN_CHANNEL_ID

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
            .setContentTitle("Passepartout")
            .setContentText("VPN is running")
            .setOngoing(true)
            .build()
    }

    private fun updateNotification(snapshot: TunnelSnapshot) {
        Log.e(Globals.TAG_SERVICE, "updateNotification()")
        val notification = NotificationCompat.Builder(this, VPN_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Passepartout")
            .setContentText("Status is ${snapshot.status}")
            .setOngoing(true)
            .build()
        NotificationManagerCompat
            .from(this)
            .notify(VPN_NOTIFICATION_ID, notification)
    }

    companion object {
        const val EXTRA_TUNNEL_PREFERENCES = "com.algoritmico.passepartout.extra.TUNNEL_PREFERENCES"
        const val VPN_CHANNEL_ID = "vpn_service_channel"
        const val VPN_NOTIFICATION_ID = 1
    }
}
