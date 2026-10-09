// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.extensions

import com.algoritmico.passepartout.models.ConfigFlag
import io.partout.models.DaemonFeatureFlag

val Set<ConfigFlag>.daemonFeatureFlags: Set<DaemonFeatureFlag>
    get() = buildSet {
        if (this@daemonFeatureFlags.contains(ConfigFlag.experimentalDaemon_202610)) {
            add(DaemonFeatureFlag.experimentalDaemon)
        }
        if (this@daemonFeatureFlags.contains(ConfigFlag.experimentalDaemonOpenVPN_202610)) {
            add(DaemonFeatureFlag.experimentalOpenVPN)
        }
        if (this@daemonFeatureFlags.contains(ConfigFlag.experimentalDaemonWireGuard_202610)) {
            add(DaemonFeatureFlag.experimentalWireGuard)
        }
    }
