// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.models.AppErrorCode
import com.algoritmico.passepartout.observables.toLastErrorCode
import com.algoritmico.passepartout.ui.extensions.LocalizedConnectionStatusError
import io.partout.models.PartoutErrorCode
import org.junit.Assert.assertEquals
import org.junit.Test

class ConnectionStatusErrorUnitTest {
    @Test
    fun appErrorCode_withConnectionStatusMapsToResource() {
        val sut = LocalizedConnectionStatusError(
            AppErrorCode.ineligibleProfile.toLastErrorCode
        )

        assertEquals(R.string.errors_app_ineligible, sut.localizedDescriptionResource)
    }

    @Test
    fun appErrorCode_withoutConnectionStatusFallsBackToGenericResource() {
        val sut = LocalizedConnectionStatusError(
            AppErrorCode.timeout.toLastErrorCode
        )

        assertEquals(R.string.errors_tunnel_generic, sut.localizedDescriptionResource)
    }

    @Test
    fun partoutErrorCode_withConnectionStatusMapsToResource() {
        val sut = LocalizedConnectionStatusError(
            PartoutErrorCode.timeout.value
        )

        assertEquals(R.string.global_nouns_timeout, sut.localizedDescriptionResource)
    }

    @Test
    fun partoutErrorCode_withoutConnectionStatusFallsBackToGenericResource() {
        val sut = LocalizedConnectionStatusError(
            PartoutErrorCode.wireGuardEmptyPeers.value
        )

        assertEquals(R.string.errors_tunnel_generic, sut.localizedDescriptionResource)
    }

    @Test
    fun unknownErrorCode_fallsBackToGenericResource() {
        val sut = LocalizedConnectionStatusError("not-a-code")

        assertEquals(R.string.errors_tunnel_generic, sut.localizedDescriptionResource)
    }
}
