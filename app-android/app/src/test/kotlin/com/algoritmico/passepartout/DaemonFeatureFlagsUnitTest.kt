// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.business.extensions.daemonFeatureFlags
import com.algoritmico.passepartout.business.extensions.default
import com.algoritmico.passepartout.business.extensions.enabledFlags
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.models.ConfigFlag
import com.algoritmico.passepartout.models.ExperimentalPreferences
import io.partout.models.DaemonFeatureFlag
import org.junit.Assert.assertEquals
import org.junit.Test

class DaemonFeatureFlagsUnitTest {
    @Test
    fun configFlags_selectIndependentDaemonFeatures() {
        val mappings = listOf(
            ConfigFlag.experimentalDaemon_202610 to DaemonFeatureFlag.experimentalDaemon,
            ConfigFlag.experimentalDaemonOpenVPN_202610 to DaemonFeatureFlag.experimentalOpenVPN,
            ConfigFlag.experimentalDaemonWireGuard_202610 to DaemonFeatureFlag.experimentalWireGuard
        )
        for (mask in 0 until (1 shl mappings.size)) {
            val selected = mappings.filterIndexed { index, _ -> mask and (1 shl index) != 0 }
            val flags = selected.map { it.first }.toSet() + ConfigFlag.appNotWorking + ConfigFlag.unknown
            assertEquals(selected.map { it.second }.toSet(), flags.daemonFeatureFlags)
        }
    }

    @Test
    fun defaultPreferences_disableExperimentalDaemonFeatures() {
        assertEquals(emptySet<DaemonFeatureFlag>(), AppPreferences.default.enabledFlags().daemonFeatureFlags)
    }

    @Test
    fun localDisable_overridesRemoteAndLocalEnable() {
        val preferences = AppPreferences.default.copy(
            configFlags = listOf(
                ConfigFlag.experimentalDaemon_202610,
                ConfigFlag.experimentalDaemonOpenVPN_202610,
                ConfigFlag.experimentalDaemonWireGuard_202610
            ),
            experimental = ExperimentalPreferences(
                ignoredConfigFlags = listOf(ConfigFlag.experimentalDaemonWireGuard_202610),
                enabledConfigFlags = listOf(ConfigFlag.experimentalDaemonWireGuard_202610)
            )
        )
        assertEquals(
            setOf(DaemonFeatureFlag.experimentalDaemon, DaemonFeatureFlag.experimentalOpenVPN),
            preferences.enabledFlags().daemonFeatureFlags
        )

        val withoutDaemon = preferences.copy(
            experimental = preferences.experimental.copy(
                ignoredConfigFlags = listOf(ConfigFlag.experimentalDaemon_202610)
            )
        )
        assertEquals(
            setOf(DaemonFeatureFlag.experimentalOpenVPN, DaemonFeatureFlag.experimentalWireGuard),
            withoutDaemon.enabledFlags().daemonFeatureFlags
        )
    }

    @Test
    fun localEnable_worksWithoutRemoteFlags() {
        val preferences = AppPreferences.default.copy(
            experimental = ExperimentalPreferences(
                ignoredConfigFlags = emptyList(),
                enabledConfigFlags = listOf(ConfigFlag.experimentalDaemonWireGuard_202610)
            )
        )
        assertEquals(
            setOf(DaemonFeatureFlag.experimentalWireGuard),
            preferences.enabledFlags().daemonFeatureFlags
        )
    }
}
