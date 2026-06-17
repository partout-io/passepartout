// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.extensions

import io.partout.models.DataCount
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

private fun Long.perSecond(elapsedMillis: Long): Long {
    if (elapsedMillis <= 0L) {
        return 0L
    }
    val delta = coerceAtLeast(0L)
    return (delta.toDouble() * 1000.0 / elapsedMillis.toDouble()).roundToLong()
}
