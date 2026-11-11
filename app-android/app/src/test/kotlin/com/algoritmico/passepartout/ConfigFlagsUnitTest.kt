// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.business.extensions.default
import com.algoritmico.passepartout.business.extensions.enabledFlags
import com.algoritmico.passepartout.business.managers.ConfigBundle
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.models.ConfigFlag
import com.algoritmico.passepartout.models.ExperimentalPreferences
import org.junit.Assert.assertEquals
import org.junit.Test

class ConfigFlagsUnitTest {
    @Test
    fun configBundle_ignoresRemovedDaemonFlags() {
        val json = """
            {
                "daemonLooperV2": {"rate": 100},
                "daemonLooperV2WireGuard": {"rate": 100},
                "experimentalDaemon_202610": {"rate": 100},
                "experimentalDaemonOpenVPN_202610": {"rate": 100},
                "experimentalDaemonWireGuard_202610": {"rate": 100},
                "appNotWorking": {"rate": 100}
            }
        """.trimIndent()
        val bundle = ConfigBundle.decode(json.toByteArray())
        assertEquals(setOf(ConfigFlag.appNotWorking), bundle.activeFlags(1))
    }

    @Test
    fun localDisable_overridesRemoteAndLocalEnable() {
        val preferences = AppPreferences.default.copy(
            configFlags = listOf(ConfigFlag.appNotWorking),
            experimental = ExperimentalPreferences(
                ignoredConfigFlags = listOf(ConfigFlag.appNotWorking),
                enabledConfigFlags = listOf(ConfigFlag.appNotWorking)
            )
        )
        assertEquals(emptySet<ConfigFlag>(), preferences.enabledFlags())
    }

    @Test
    fun localEnable_worksWithoutRemoteFlags() {
        val preferences = AppPreferences.default.copy(
            experimental = ExperimentalPreferences(
                ignoredConfigFlags = emptyList(),
                enabledConfigFlags = listOf(ConfigFlag.appNotWorking)
            )
        )
        assertEquals(setOf(ConfigFlag.appNotWorking), preferences.enabledFlags())
    }
}
