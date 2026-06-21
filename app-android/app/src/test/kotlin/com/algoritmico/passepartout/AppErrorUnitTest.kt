// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.business.managers.ProfileManagerException
import com.algoritmico.passepartout.models.AppErrorCode
import com.algoritmico.passepartout.observables.ProfileImporterException
import com.algoritmico.passepartout.observables.TunnelObservableException
import com.algoritmico.passepartout.observables.asAppError
import io.partout.abi.PartoutException
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class AppErrorUnitTest {
    @Test
    fun profileManagerABI_decodesAppErrorPayload() {
        val error = ProfileManagerException.ABI(
            """{"code":"wireGuardEmptyPeers","description":"ignored"}"""
        )

        val appError = error.asAppError

        assertEquals(AppErrorCode.wireGuardEmptyPeers, appError.code)
        assertEquals("ignored", appError.description)
    }

    @Test
    fun profileManagerABI_mapsPlainPayloadToImportError() {
        val error = ProfileManagerException.ABI("parser details")

        val appError = error.asAppError

        assertEquals(AppErrorCode.importError, appError.code)
        assertEquals("parser details", appError.description)
    }

    @Test
    fun profileImporterFailure_keepsImporterWrapper() {
        val error = ProfileImporterException.Failure(
            ProfileManagerException.ABI("parser details")
        )

        val appError = error.asAppError

        assertEquals(AppErrorCode.importError, appError.code)
        assertTrue(appError.cause is ProfileImporterException.Failure)
    }

    @Test
    fun tunnelObservableExceptions_mapToAppErrorCodes() {
        assertEquals(
            AppErrorCode.other,
            TunnelObservableException.Generic.asAppError.code
        )
        assertEquals(
            AppErrorCode.permissionDenied,
            TunnelObservableException.VpnPermissionDenied.asAppError.code
        )
    }

    @Test
    fun partoutException_fallsBackToPartoutCode() {
        val error = PartoutException(1, null)

        val appError = error.asAppError

        assertEquals(AppErrorCode.partout, appError.code)
        assertEquals("1", appError.description)
    }
}
