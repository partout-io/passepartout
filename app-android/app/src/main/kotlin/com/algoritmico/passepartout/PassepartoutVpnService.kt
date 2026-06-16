// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.app.Notification
import android.app.PendingIntent
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
import com.algoritmico.passepartout.injection.JSON
import com.algoritmico.passepartout.injection.Tags
import com.algoritmico.passepartout.injection.lastTunnelPreferences
import com.algoritmico.passepartout.injection.lastTunnelProfile
import com.algoritmico.passepartout.ui.NotificationTransferFormatter
import io.partout.PartoutVpnServiceRuntime
import io.partout.abi.PartoutException
import io.partout.models.TaggedProfile
import io.partout.models.TunnelSnapshot
import io.partout.vpn.JNITunnelController
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class PassepartoutVpnService: VpnService() {
    private val logTag = Tags.SERVICE
    private val jniLogTag = Tags.PARTOUT_JNI

    @Volatile
    private var currentProfileName: String? = null

    @Volatile
    private var shouldKeepStoppedNotification = false

    private val notificationTransfer = NotificationTransferFormatter()

    private val runtime by lazy {
        PartoutVpnServiceRuntime(
            logTag = logTag,
            jniLogTag = jniLogTag,
            service = this,
            engine = engine
        )
    }

    private val engine = object : PartoutVpnServiceRuntime.Engine {
        private val library = PassepartoutWrapper()
        private val lastProfileFile: File
            get() = applicationContext.lastTunnelProfile
        private val lastPreferencesFile: File
            get() = applicationContext.lastTunnelPreferences

        override suspend fun start(
            intent: Intent?,
            controller: JNITunnelController,
            profileJSON: String
        ) = withContext(Dispatchers.IO) {
            // FIXME: ###: Load tunnel bundle/constants/preferences
//            val bundle = appBundleJSON()
//            Log.e(logTag, ">>> Bundle: $bundle")
//            updateCurrentProfileName(profileJSON)
//
//            // Try preferences from intent, otherwise load last persisted
//            val intentPreferencesJSON = intent?.getStringExtra(EXTRA_TUNNEL_PREFERENCES)
//            val preferencesJSON = if (intentPreferencesJSON.isNullOrBlank()) {
//                Log.i(logTag, "Load last preferences")
//                readLastPreferences()
//            } else {
//                Log.i(logTag, "Load and persist start preferences")
//                writeLastPreferences(intentPreferencesJSON)
//                intentPreferencesJSON
//            }

            // This call retains the controller strongly
            library.partoutInit(Tags.PARTOUT)
            val code = library.partoutDaemonStart(
                profileJSON,
                cacheDir.absolutePath,
                controller
            )
            if (code != 0) {
                throw PartoutException(code, null)
            }
        }

        override suspend fun stop() = withContext(Dispatchers.IO) {
            val result = CompletableDeferred<Unit>()
            library.partoutDaemonStop { code, payload ->
                if (code != 0) {
                    result.completeExceptionally(PartoutException(code, payload))
                    return@partoutDaemonStop
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

        override suspend fun deleteLastProfile(id: String) {
            withContext(Dispatchers.IO) {
                runCatching {
                    val json = readLastFile(lastProfileFile)
                    val profile = JSON.decode<TaggedProfile>(json)
                    if (profile.id != id) { return@runCatching }
                    Log.i(logTag, "Forget last profile ($id)")
                    lastProfileFile.delete()
                }.onFailure {
                    Log.e(logTag, "Unable to forget last profile", it)
                }
            }
        }

        override fun onSnapshot(snapshot: TunnelSnapshot) {
            updateNotification(snapshot)
        }

        override fun onServiceStopped() {
            postStoppedNotification()
        }

        private fun readLastPreferences(): String? {
            return runCatching {
                readLastFile(lastPreferencesFile)
            }.onFailure {
                Log.w(logTag, "Unable to read last tunnel preferences", it)
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
        if (intent?.action == PartoutVpnServiceRuntime.ACTION_STOP_VPN) {
            return runtime.onStartCommand(intent, flags, startId)
        }
        shouldKeepStoppedNotification = false
        intent?.getStringExtra(PartoutVpnServiceRuntime.EXTRA_PROFILE_JSON)?.let {
            notificationTransfer.reset()
            updateCurrentProfileName(it)
        }
        ServiceCompat.startForeground(
            this,
            VPN_NOTIFICATION_ID,
            createNotification(snapshot = null),
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED
        )
        return runtime.onStartCommand(intent, flags, startId)
    }

    override fun onDestroy() {
        if (!shouldKeepStoppedNotification) {
            dismissNotification()
        }
        runtime.onDestroy()
        resetNotificationState()
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

    private fun createNotification(
        snapshot: TunnelSnapshot?,
        isServiceStopped: Boolean = false
    ): Notification {
        val channelId = VPN_CHANNEL_ID

        // Create a notification channel (required on Android 8.0+)
        val channel = NotificationChannelCompat.Builder(
            channelId,
            NotificationManagerCompat.IMPORTANCE_LOW // low importance to avoid sound
        )
            .setName("Passepartout VPN")
            .setDescription("Notification for the VPN foreground service")
            .setShowBadge(false)
            .build()

        NotificationManagerCompat
            .from(this)
            .createNotificationChannel(channel)

        val title = currentProfileName ?: getString(R.string.app_name)

        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.ic_notification_vpn)
            .setContentTitle(title)
            .setSubText(if (isServiceStopped) "stopped" else snapshot?.status?.toString())
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOnlyAlertOnce(true)
            .setOngoing(!isServiceStopped)
            .setAutoCancel(false)
            .addAction(
                R.drawable.ic_notification_vpn,
                if (isServiceStopped) "Connect" else "Disconnect",
                if (isServiceStopped) connectPendingIntent() else disconnectPendingIntent()
            )

        val content = snapshot?.let(notificationTransfer::activeText)
        if (content != null) {
            builder
                .setContentText(content)
                .setStyle(NotificationCompat.BigTextStyle().bigText(content))
        }

        return builder.build()
    }

    private fun updateNotification(snapshot: TunnelSnapshot) {
        Log.e(logTag, "updateNotification()")
        val notificationManager = NotificationManagerCompat.from(this)
        if (!notificationManager.areNotificationsEnabled()) {
            Log.w(logTag, "Skip VPN notification update, notifications are disabled")
            return
        }
        val notification = createNotification(snapshot)
        runCatching {
            notificationManager.notify(VPN_NOTIFICATION_ID, notification)
        }.onFailure {
            if (it is SecurityException) {
                Log.w(logTag, "Unable to update VPN notification", it)
            } else {
                throw it
            }
        }
    }

    private fun postStoppedNotification() {
        shouldKeepStoppedNotification = true
        notificationTransfer.reset()
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_DETACH)

        val notificationManager = NotificationManagerCompat.from(this)
        if (!notificationManager.areNotificationsEnabled()) {
            Log.w(logTag, "Skip stopped VPN notification, notifications are disabled")
            return
        }
        val notification = createNotification(
            snapshot = null,
            isServiceStopped = true
        )
        runCatching {
            notificationManager.notify(VPN_NOTIFICATION_ID, notification)
        }.onFailure {
            if (it is SecurityException) {
                Log.w(logTag, "Unable to show stopped VPN notification", it)
            } else {
                throw it
            }
        }
    }

    private fun connectPendingIntent(): PendingIntent {
        val intent = Intent(this, PassepartoutVpnService::class.java)
        return PendingIntent.getService(
            this,
            VPN_CONNECT_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun disconnectPendingIntent(): PendingIntent {
        val intent = Intent(this, PassepartoutVpnService::class.java).apply {
            action = PartoutVpnServiceRuntime.ACTION_STOP_VPN
        }
        return PendingIntent.getService(
            this,
            VPN_DISCONNECT_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun dismissNotification() {
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        NotificationManagerCompat
            .from(this)
            .cancel(VPN_NOTIFICATION_ID)
    }

    private fun resetNotificationState() {
        currentProfileName = null
        notificationTransfer.reset()
    }

    private fun updateCurrentProfileName(profileJSON: String) {
        runCatching {
            JSON.decode<TaggedProfile>(profileJSON).name
        }.onSuccess {
            currentProfileName = it
        }.onFailure {
            Log.w(logTag, "Unable to decode VPN profile name", it)
        }
    }

    companion object {
        const val EXTRA_TUNNEL_PREFERENCES = "com.algoritmico.passepartout.extra.TUNNEL_PREFERENCES"
        const val VPN_CHANNEL_ID = "vpn_service_channel_1"
        const val VPN_NOTIFICATION_ID = 1
        private const val VPN_CONNECT_REQUEST_CODE = 1000
        private const val VPN_DISCONNECT_REQUEST_CODE = 1001
    }
}
