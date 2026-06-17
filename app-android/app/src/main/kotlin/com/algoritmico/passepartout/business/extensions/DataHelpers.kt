// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.extensions

import io.partout.models.DataCount
import java.util.Locale
import kotlin.math.roundToLong

data class DataSpeed(
    val received: Long,
    val sent: Long
) {
    companion object {
        val ZERO = DataSpeed(received = 0L, sent = 0L)
    }
}

data class DataSample(
    val id: String,
    val dataCount: DataCount,
    val elapsedRealtimeMillis: Long
)

fun DataCount.speedSince(
    previous: DataSample?,
    id: String,
    elapsedRealtimeMillis: Long
): DataSpeed {
    if (previous == null || previous.id != id) {
        return DataSpeed.ZERO
    }
    val elapsedMillis = elapsedRealtimeMillis - previous.elapsedRealtimeMillis
    return DataSpeed(
        received = (received - previous.dataCount.received).perSecond(elapsedMillis),
        sent = (sent - previous.dataCount.sent).perSecond(elapsedMillis)
    )
}

fun Long.formatDataUnit(): String {
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

fun Long.formatDecimalDataUnit(unitSize: Long, unit: String): String {
    val count = toDouble() / unitSize.toDouble()
    return String.format(Locale.US, "%.2f%s", count, unit)
}

fun Long.perSecond(elapsedMillis: Long): Long {
    if (elapsedMillis <= 0L) {
        return 0L
    }
    val delta = coerceAtLeast(0L)
    return (delta.toDouble() * 1000.0 / elapsedMillis.toDouble()).roundToLong()
}

private const val KILOBYTE = 1024L
private const val MEGABYTE = KILOBYTE * 1024L
private const val GIGABYTE = MEGABYTE * 1024L
