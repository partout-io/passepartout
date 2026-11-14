// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.ui.extensions.uuidText
import org.junit.Assert.assertEquals
import org.junit.Test

class UUIDUIUnitTest {
    @Test
    fun formatsUUIDAsTwoRowsOfFourUppercaseBlocks() {
        assertEquals(
            "0011 2233 4455 6677\n8899 AABB CCDD EEFF",
            "00112233-4455-6677-8899-aabbccddeeff".uuidText()
        )
    }
}
