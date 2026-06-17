// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.models

import android.os.SystemClock
import io.partout.models.DataCount
import io.partout.models.TunnelSnapshot
import io.partout.models.TunnelStatus
import java.util.Locale
import kotlin.math.roundToLong

internal class NotificationTransferFormatter {
    private var lastSample: NotificationTransferSample? = null

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
            tunnelId = snapshot.id,
            elapsedRealtimeMillis = now
        )
        lastSample = NotificationTransferSample(
            tunnelId = snapshot.id,
            dataCount = dataCount,
            elapsedRealtimeMillis = now
        )
        return speed.notificationText()
    }
}

private fun DataSpeed.notificationText(): String {
    return "↓ ${received.formatDataUnit()}/s ↑ ${sent.formatDataUnit()}/s"
}

private fun DataCount.speedSince(
    previous: NotificationTransferSample?,
    tunnelId: String,
    elapsedRealtimeMillis: Long
): DataSpeed {
    if (previous == null || previous.tunnelId != tunnelId) {
        return DataSpeed.ZERO
    }
    val elapsedMillis = elapsedRealtimeMillis - previous.elapsedRealtimeMillis
    return DataSpeed(
        received = (received - previous.dataCount.received).perSecond(elapsedMillis),
        sent = (sent - previous.dataCount.sent).perSecond(elapsedMillis)
    )
}

private fun Long.perSecond(elapsedMillis: Long): Long {
    if (elapsedMillis <= 0L) {
        return 0L
    }
    val delta = coerceAtLeast(0L)
    return (delta.toDouble() * 1000.0 / elapsedMillis.toDouble()).roundToLong()
}

private fun Long.formatDataUnit(): String {
    val value = coerceAtLeast(0L)
    if (value == 0L) {
        return "0B"
    }
    if (value < KILOBYTE) {
        return "${value}B"
    }
    return when {
        value >= GIGABYTE / 10L -> value.formatDecimalDataUnit(GIGABYTE, "GB")
        value >= MEGABYTE / 10L -> value.formatDecimalDataUnit(MEGABYTE, "MB")
        else -> "${value / KILOBYTE}kB"
    }
}

private fun Long.formatDecimalDataUnit(unitSize: Long, unit: String): String {
    val count = toDouble() / unitSize.toDouble()
    return String.format(Locale.US, "%.2f%s", count, unit)
}

private data class NotificationTransferSample(
    val tunnelId: String,
    val dataCount: DataCount,
    val elapsedRealtimeMillis: Long
)

private data class DataSpeed(
    val received: Long,
    val sent: Long
) {
    companion object {
        val ZERO = DataSpeed(received = 0L, sent = 0L)
    }
}

private const val KILOBYTE = 1024L
private const val MEGABYTE = KILOBYTE * 1024L
private const val GIGABYTE = MEGABYTE * 1024L
