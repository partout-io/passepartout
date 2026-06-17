// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.models

import android.os.SystemClock
import com.algoritmico.passepartout.extensions.DataSample
import com.algoritmico.passepartout.extensions.DataSpeed
import com.algoritmico.passepartout.extensions.formatDataUnit
import com.algoritmico.passepartout.extensions.speedSince
import io.partout.models.TunnelSnapshot
import io.partout.models.TunnelStatus

class NotificationTransferFormatter {
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
