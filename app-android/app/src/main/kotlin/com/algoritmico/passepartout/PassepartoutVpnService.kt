// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.Manifest
import android.app.Notification
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.IBinder
import android.util.AtomicFile
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import com.algoritmico.passepartout.business.extensions.JSON
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.context.Tags
import com.algoritmico.passepartout.context.LocalConstants
import com.algoritmico.passepartout.context.appBundle
import com.algoritmico.passepartout.context.lastTunnelPreferences
import com.algoritmico.passepartout.context.lastTunnelProfile
import com.algoritmico.passepartout.context.logPreamble
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.ui.extensions.NotificationTransferFormatter
import io.partout.NativeTunnelControllerJNI
import io.partout.PartoutVpnServiceRuntime
import io.partout.abi.PartoutException
import io.partout.models.TaggedProfile
import io.partout.models.TunnelSnapshot
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
            controller: NativeTunnelControllerJNI,
            profileJSON: String
        ) = withContext(Dispatchers.IO) {
            applicationContext.logPreamble(logTag)

            AppLog.i(logTag, "Started service")
            val bundle = applicationContext.appBundle()
            AppLog.d(logTag, "Bundle: $bundle")
            updateCurrentProfileName(profileJSON)

            // Try preferences from intent, otherwise load last persisted
            val preferences = readPreferences(intent)
            AppLog.i(logTag, "Preferences: $preferences")

            // Initialize the library with the intent preferences
//            val openvpn_version = preferences?.configFlags ? 3 : 2
            val logsPrivateData = preferences?.logsPrivateData ?: false
            library.partoutInit(Tags.SERVICE_PARTOUT, logsPrivateData)

            // This call retains the controller strongly
            val code = library.partoutDaemonStart(
                profileJSON,
                cacheDir.absolutePath,
                controller,
                logsSnapshots
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
                runCatchingNonFatal {
                    val json = readLastFile(lastProfileFile)
                    val profile = JSON.decode<TaggedProfile>(json)
                    if (profile.id != id) { return@runCatchingNonFatal }
                    AppLog.i(logTag, "Forget last profile $id")
                    lastProfileFile.delete()
                }.onFailure {
                    AppLog.w(logTag, "Unable to forget last profile", it)
                }
            }
        }

        override fun onSnapshot(snapshot: TunnelSnapshot) {
            updateNotification(snapshot)
        }

        override fun onServiceStopped() {
            postStoppedNotification()
        }

        override val logsSnapshots: Boolean
            get() = LocalConstants.TUNNEL_LOGS_SNAPSHOTS

        private fun readPreferences(intent: Intent?): AppPreferences? {
            val intentPreferencesJSON = intent?.getStringExtra(EXTRA_TUNNEL_PREFERENCES)
            val preferencesJSON = if (intentPreferencesJSON.isNullOrBlank()) {
                AppLog.i(logTag, "Load last preferences")
                runCatchingNonFatal {
                    readLastFile(lastPreferencesFile)
                }.onFailure {
                    AppLog.w(logTag, "Unable to read last tunnel preferences", it)
                }.getOrNull()
            } else {
                AppLog.i(logTag, "Load and persist start preferences")
                runCatchingNonFatal {
                    writeLastFile(lastPreferencesFile, intentPreferencesJSON)
                }.onFailure {
                    AppLog.w(logTag, "Unable to write last tunnel preferences", it)
                }
                intentPreferencesJSON
            }
            return preferencesJSON?.let { json ->
                runCatchingNonFatal {
                    JSON.decode<AppPreferences>(json)
                }.onFailure {
                    AppLog.w(logTag, "Unable to decode preferences JSON", it)
                }.getOrNull()
            }
        }

        private fun readLastFile(file: File): String {
            return AtomicFile(file).openRead().bufferedReader(Charsets.UTF_8).use {
                it.readText()
            }
        }

        private fun writeLastFile(file: File, json: String) {
            val atomicFile = AtomicFile(file)
            val stream = atomicFile.startWrite()
            runCatchingNonFatal {
                stream.write(json.toByteArray(Charsets.UTF_8))
                atomicFile.finishWrite(stream)
            }.onFailure {
                atomicFile.failWrite(stream)
                throw it
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
        try {
            if (!canPostNotifications()) {
                AppLog.w(logTag, "Starting service in foreground with notifications disabled")
            }
            startForegroundGracefully(createNotification(snapshot = null))
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
        if (engine.logsSnapshots) {
            AppLog.d(logTag, "updateNotification()")
        }
        val notificationManager = NotificationManagerCompat.from(this)
        if (!canPostNotifications(notificationManager)) {
            if (engine.logsSnapshots) {
                AppLog.w(logTag, "Skip VPN notification update, notifications are disabled")
            }
            return
        }
        val notification = createNotification(snapshot)
        try {
            notificationManager.notify(VPN_NOTIFICATION_ID, notification)
        } catch (it: SecurityException) {
            AppLog.w(logTag, "Unable to update VPN notification", it)
        }
    }

    private fun postStoppedNotification() {
        shouldKeepStoppedNotification = true
        notificationTransfer.reset()
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_DETACH)

        val notificationManager = NotificationManagerCompat.from(this)
        if (!canPostNotifications(notificationManager)) {
            AppLog.w(logTag, "Skip stopped VPN notification, notifications are disabled")
            return
        }
        val notification = createNotification(
            snapshot = null,
            isServiceStopped = true
        )
        try {
            notificationManager.notify(VPN_NOTIFICATION_ID, notification)
        } catch (it: SecurityException) {
            AppLog.w(logTag, "Unable to show stopped VPN notification", it)
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

    private fun startForegroundGracefully(notification: Notification) {
        ServiceCompat.startForeground(
            this,
            VPN_NOTIFICATION_ID,
            notification,
            vpnForegroundServiceType
        )
    }

    private val vpnForegroundServiceType: Int
        get() {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED
            } else {
                0
            }
        }

    private fun canPostNotifications(
        notificationManager: NotificationManagerCompat = NotificationManagerCompat.from(this)
    ): Boolean {
        if (!notificationManager.areNotificationsEnabled()) {
            return false
        }
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED
    }

    private fun resetNotificationState() {
        currentProfileName = null
        notificationTransfer.reset()
    }

    private fun updateCurrentProfileName(profileJSON: String) {
        runCatchingNonFatal {
            JSON.decode<TaggedProfile>(profileJSON).name
        }.onSuccess {
            currentProfileName = it
        }.onFailure {
            AppLog.w(logTag, "Unable to decode VPN profile name", it)
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
