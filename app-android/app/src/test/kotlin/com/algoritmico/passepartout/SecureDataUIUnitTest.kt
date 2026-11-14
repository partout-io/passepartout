// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.ui.extensions.base64ToHex
import org.junit.Assert.*
import org.junit.Test

class SecureDataUIUnitTest {
    @Test
    fun displaysDecodedBytesAsLowercaseHex() {
        assertEquals("00017f80feff", "AAF/gP7/".base64ToHex())
        assertEquals("74657374", "dGVzdA==".base64ToHex())
    }

    @Test
    fun malformedDataDoesNotCrashPresentation() {
        assertNull("not base64!".base64ToHex())
        assertEquals("", "".base64ToHex())
    }
}
