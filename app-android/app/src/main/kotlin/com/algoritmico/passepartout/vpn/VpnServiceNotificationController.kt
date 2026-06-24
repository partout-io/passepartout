// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.vpn

import android.Manifest
import android.app.Notification
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.SystemClock
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.business.extensions.DataSample
import com.algoritmico.passepartout.business.extensions.DataSpeed
import com.algoritmico.passepartout.business.extensions.JSON
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.extensions.speedSince
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.ui.extensions.formatDataUnit
import io.partout.PartoutVpnServiceRuntime
import io.partout.models.TaggedProfile
import io.partout.models.TunnelSnapshot
import io.partout.models.TunnelStatus

class VpnServiceNotificationController(
    private val logTag: String,
    private val service: VpnService,
    private val serviceClass: Class<out VpnService>,
    private val logsSnapshots: Boolean
) {
    @Volatile
    private var currentProfileName: String? = null

    @Volatile
    private var lastNotificationContent: NotificationContent? = null

    private val sampleFormatter = SampleFormatter()

    fun prepareStart(profileJSON: String?) {
        profileJSON?.let {
            resetNotificationState()
            updateProfileName(it)
        }
    }

    fun updateProfileName(profileJSON: String) {
        runCatchingNonFatal {
            JSON.decode<TaggedProfile>(profileJSON).name
        }.onSuccess {
            currentProfileName = it
        }.onFailure {
            AppLog.w(logTag, "Unable to decode VPN profile name", it)
        }
    }

    fun startForeground() {
        if (!canPostNotifications()) {
            AppLog.w(logTag, "Starting service in foreground with notifications disabled")
        }
        val content = notificationContent(snapshot = null)
        ServiceCompat.startForeground(
            service,
            VPN_NOTIFICATION_ID,
            createNotification(content),
            vpnForegroundServiceType
        )
        lastNotificationContent = content
    }

    fun update(snapshot: TunnelSnapshot) {
        if (logsSnapshots) {
            AppLog.d(logTag, "updateNotification()")
        }
        val notificationManager = NotificationManagerCompat.from(service)
        if (!canPostNotifications(notificationManager)) {
            if (logsSnapshots) {
                AppLog.w(logTag, "Skip VPN notification update, notifications are disabled")
            }
            return
        }
        val content = notificationContent(snapshot)
        if (content == lastNotificationContent) {
            if (logsSnapshots) {
                AppLog.d(logTag, "Skip unchanged VPN notification")
            }
            return
        }
        val notification = createNotification(content)
        try {
            notificationManager.notify(VPN_NOTIFICATION_ID, notification)
            lastNotificationContent = content
        } catch (it: SecurityException) {
            AppLog.w(logTag, "Unable to update VPN notification", it)
        }
    }

    @Suppress("UNUSED_PARAMETER")
    fun onServiceStopped(wasRevoked: Boolean) {
        dismiss()
        reset()
    }

    fun onDestroy() {
        dismiss()
        reset()
    }

    private fun dismiss() {
        ServiceCompat.stopForeground(service, ServiceCompat.STOP_FOREGROUND_REMOVE)
        NotificationManagerCompat
            .from(service)
            .cancel(VPN_NOTIFICATION_ID)
    }

    private fun createNotification(content: NotificationContent): Notification {
        val channel = NotificationChannelCompat.Builder(
            VPN_CHANNEL_ID,
            NotificationManagerCompat.IMPORTANCE_LOW
        )
            .setName(service.getString(R.string.app_name))
            .setDescription(service.getString(R.string.android_vpn_service_channel_description))
            .setShowBadge(false)
            .build()

        NotificationManagerCompat
            .from(service)
            .createNotificationChannel(channel)

        val builder = NotificationCompat.Builder(service, VPN_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_vpn)
            .setContentTitle(content.title)
            .setSubText(content.subText)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .setAutoCancel(false)
            .addAction(
                R.drawable.ic_notification_vpn,
                service.getString(R.string.global_actions_disconnect),
                disconnectPendingIntent()
            )

        val contentText = content.contentText
        if (contentText != null) {
            builder
                .setContentText(contentText)
                .setStyle(NotificationCompat.BigTextStyle().bigText(contentText))
        }

        return builder.build()
    }

    private fun notificationContent(snapshot: TunnelSnapshot?): NotificationContent {
        return NotificationContent(
            title = currentProfileName ?: service.getString(R.string.app_name),
            subText = notificationSubText(snapshot),
            contentText = snapshot?.let(sampleFormatter::activeText)
        )
    }

    private fun notificationSubText(snapshot: TunnelSnapshot?): String? {
        return snapshot?.status?.let(::tunnelStatusText)
    }

    private fun tunnelStatusText(status: TunnelStatus): String {
        val resId = when (status) {
            TunnelStatus.inactive -> R.string.entities_tunnel_status_inactive
            TunnelStatus.activating -> R.string.entities_tunnel_status_activating
            TunnelStatus.active -> R.string.entities_tunnel_status_active
            TunnelStatus.deactivating -> R.string.entities_tunnel_status_deactivating
        }
        return service.getString(resId)
    }

    private fun disconnectPendingIntent(): PendingIntent {
        val intent = Intent(service, serviceClass).apply {
            action = PartoutVpnServiceRuntime.ACTION_STOP_VPN
        }
        return PendingIntent.getService(
            service,
            VPN_DISCONNECT_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
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
        notificationManager: NotificationManagerCompat = NotificationManagerCompat.from(service)
    ): Boolean {
        if (!notificationManager.areNotificationsEnabled()) {
            return false
        }
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                ContextCompat.checkSelfPermission(
                    service,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED
    }

    private fun reset() {
        currentProfileName = null
        resetNotificationState()
    }

    private fun resetNotificationState() {
        lastNotificationContent = null
        sampleFormatter.reset()
    }

    companion object {
        private const val VPN_CHANNEL_ID = "vpn_service_channel_1"
        private const val VPN_NOTIFICATION_ID = 1
        private const val VPN_DISCONNECT_REQUEST_CODE = 1001
    }
}

private data class NotificationContent(
    val title: String,
    val subText: String?,
    val contentText: String?
)

private class SampleFormatter {
    private var lastSample: DataSample? = null

    @Synchronized
    fun reset() {
        lastSample = null
    }

    @Synchronized
    fun activeText(snapshot: TunnelSnapshot): String? {
        if (snapshot.status != TunnelStatus.active) {
            lastSample = null
            return null
        }
        val dataCount = snapshot.environment?.dataCount ?: return null
        val now = SystemClock.elapsedRealtime()
        val speed = dataCount.speedSince(
            previous = lastSample,
            id = snapshot.id,
            elapsedRealtimeMillis = now
        )
        lastSample = DataSample(
            id = snapshot.id,
            dataCount = dataCount,
            elapsedRealtimeMillis = now
        )
        return speed.notificationText()
    }
}

private fun DataSpeed.notificationText(): String {
    return "↓ ${received.formatDataUnit()}/s ↑ ${sent.formatDataUnit()}/s"
}
