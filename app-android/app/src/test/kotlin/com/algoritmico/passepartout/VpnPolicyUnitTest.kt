// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import io.partout.VpnPolicy
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class VpnPolicyUnitTest {
    @Test
    fun stickyRestartDoesNotImplyAlwaysOn() {
        assertNull(VpnPolicy().afterLegacyStart(false, false, false).alwaysOn)
    }

    @Test
    fun appRestorationDoesNotImplyAlwaysOn() {
        assertNull(VpnPolicy().afterLegacyStart(true, true, false).alwaysOn)
    }

    @Test
    fun systemStartInfersAlwaysOnButNotLockdown() {
        val policy = VpnPolicy().afterLegacyStart(true, false, false)
        assertEquals(true, policy.alwaysOn)
        assertNull(policy.lockdown)
    }

    @Test
    fun stickyRestartPreservesPriorInference() {
        assertEquals(true, VpnPolicy(true).afterLegacyStart(false, false, false).alwaysOn)
    }

    @Test
    fun stopCommandDoesNotImplyAlwaysOn() {
        assertNull(VpnPolicy().afterLegacyStart(true, false, true).alwaysOn)
    }
}
