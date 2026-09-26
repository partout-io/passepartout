// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.business.extensions.openVPN
import com.algoritmico.passepartout.business.extensions.wireGuard
import com.algoritmico.passepartout.models.AppErrorCode
import com.algoritmico.passepartout.observables.toLastErrorCode
import com.algoritmico.passepartout.ui.extensions.LocalizedConnectionStatusError
import io.partout.abi.rawValue
import io.partout.models.OpenVPNErrorCode
import io.partout.models.PartoutErrorCode
import io.partout.models.PartoutErrorPair
import io.partout.models.WireGuardErrorCode
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
            PartoutErrorPair.wireGuard(WireGuardErrorCode.emptyPeers).rawValue
        )

        assertEquals(R.string.errors_tunnel_generic, sut.localizedDescriptionResource)
    }

    @Test
    fun protocolSubCode_mapsToResource() {
        assertEquals(
            R.string.errors_tunnel_tls,
            LocalizedConnectionStatusError(PartoutErrorPair.openVPN(OpenVPNErrorCode.tlsFailure).rawValue).localizedDescriptionResource
        )
        assertEquals(
            R.string.errors_tunnel_generic,
            LocalizedConnectionStatusError(PartoutErrorPair(PartoutErrorCode.openVPN, "unknown").rawValue).localizedDescriptionResource
        )
    }

    @Test
    fun unknownErrorCode_fallsBackToGenericResource() {
        val sut = LocalizedConnectionStatusError("not-a-code")

        assertEquals(R.string.errors_tunnel_generic, sut.localizedDescriptionResource)
    }
}
