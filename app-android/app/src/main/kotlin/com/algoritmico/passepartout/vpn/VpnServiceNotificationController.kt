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
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.business.extensions.JSON
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AppLog
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
    private var shouldKeepStoppedNotification = false

    private val notificationTransfer = NotificationTransferFormatter()

    fun prepareStart(profileJSON: String?) {
        shouldKeepStoppedNotification = false
        profileJSON?.let {
            notificationTransfer.reset()
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
        ServiceCompat.startForeground(
            service,
            VPN_NOTIFICATION_ID,
            createNotification(snapshot = null),
            vpnForegroundServiceType
        )
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
        val notification = createNotification(snapshot)
        try {
            notificationManager.notify(VPN_NOTIFICATION_ID, notification)
        } catch (it: SecurityException) {
            AppLog.w(logTag, "Unable to update VPN notification", it)
        }
    }

    fun onServiceStopped(wasRevoked: Boolean) {
        if (wasRevoked) {
            shouldKeepStoppedNotification = false
            dismiss()
            reset()
            return
        }
        postStopped()
    }

    fun onDestroy() {
        if (!shouldKeepStoppedNotification) {
            dismiss()
        }
        reset()
    }

    private fun postStopped() {
        shouldKeepStoppedNotification = true
        notificationTransfer.reset()
        ServiceCompat.stopForeground(service, ServiceCompat.STOP_FOREGROUND_DETACH)

        val notificationManager = NotificationManagerCompat.from(service)
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

    private fun dismiss() {
        ServiceCompat.stopForeground(service, ServiceCompat.STOP_FOREGROUND_REMOVE)
        NotificationManagerCompat
            .from(service)
            .cancel(VPN_NOTIFICATION_ID)
    }

    private fun createNotification(
        snapshot: TunnelSnapshot?,
        isServiceStopped: Boolean = false
    ): Notification {
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

        val title = currentProfileName ?: service.getString(R.string.app_name)

        val builder = NotificationCompat.Builder(service, VPN_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_vpn)
            .setContentTitle(title)
            .setSubText(notificationSubText(snapshot, isServiceStopped))
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOnlyAlertOnce(true)
            .setOngoing(!isServiceStopped)
            .setAutoCancel(false)
            .addAction(
                R.drawable.ic_notification_vpn,
                service.getString(
                    if (isServiceStopped) {
                        R.string.global_actions_connect
                    } else {
                        R.string.global_actions_disconnect
                    }
                ),
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

    private fun notificationSubText(
        snapshot: TunnelSnapshot?,
        isServiceStopped: Boolean
    ): String? {
        if (isServiceStopped) {
            return service.getString(R.string.android_vpn_service_status_stopped)
        }
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

    private fun connectPendingIntent(): PendingIntent {
        val intent = Intent(service, serviceClass)
        return PendingIntent.getService(
            service,
            VPN_CONNECT_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
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
        shouldKeepStoppedNotification = false
        notificationTransfer.reset()
    }

    companion object {
        private const val VPN_CHANNEL_ID = "vpn_service_channel_1"
        private const val VPN_NOTIFICATION_ID = 1
        private const val VPN_CONNECT_REQUEST_CODE = 1000
        private const val VPN_DISCONNECT_REQUEST_CODE = 1001
    }
}
