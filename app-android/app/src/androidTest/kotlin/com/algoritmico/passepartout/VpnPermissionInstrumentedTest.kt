// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.content.Intent
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.algoritmico.passepartout.observables.VpnPermissionObservable
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class VpnPermissionInstrumentedTest {
    @Test
    fun pendingRequestSurvivesWithoutCollectorAndIsClaimedOnce() {
        val observable = VpnPermissionObservable()
        val intent = Intent("vpn.permission")
        observable.request(intent)
        assertSame(intent, observable.state.value?.intent)
        assertFalse(observable.complete())
        assertSame(intent, observable.takePendingRequest())
        assertTrue(observable.state.value!!.isLaunched)
        // A replacement activity observes the same state without launching again.
        assertNull(observable.takePendingRequest())
        assertTrue(observable.complete())
        assertNull(observable.state.value)
        assertFalse(observable.complete())
    }

    @Test
    fun repeatedRequestDoesNotReplaceOutstandingPrompt() {
        val observable = VpnPermissionObservable()
        val first = Intent("first")
        val next = Intent("next")
        observable.request(first)
        observable.request(next)
        assertSame(first, observable.takePendingRequest())
        observable.request(next)
        assertNull(observable.takePendingRequest())
        observable.complete()
        observable.request(next)
        assertSame(next, observable.takePendingRequest())
    }
}
