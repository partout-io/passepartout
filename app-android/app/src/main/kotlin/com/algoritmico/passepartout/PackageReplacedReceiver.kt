// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.context.defaultAndroidConstants
import com.algoritmico.passepartout.vpn.VpnServiceStore

class PackageReplacedReceiver: BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) {
            return
        }
        val constants = defaultAndroidConstants
        val store = VpnServiceStore(
            logTag = constants.tags.service,
            context = context,
            storage = constants.storage
        )
        if (!store.wasTunnelRunning) {
            return
        }
        AppLog.i(constants.tags.service, "Restart VPN after app update")
        runCatchingNonFatal {
            ContextCompat.startForegroundService(
                context,
                Intent(context, PassepartoutVpnService::class.java)
            )
        }.onFailure {
            AppLog.e(constants.tags.service, "Unable to restart VPN after app update", it)
        }
    }
}
