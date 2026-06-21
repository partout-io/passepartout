// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import com.algoritmico.passepartout.business.extensions.GenericException
import com.algoritmico.passepartout.business.managers.ConfigManagerException
import com.algoritmico.passepartout.business.managers.ProfileManagerException
import com.algoritmico.passepartout.business.managers.VersionCheckerException
import com.algoritmico.passepartout.models.AppErrorCode
import io.partout.abi.PartoutException
import io.partout.models.PartoutErrorCode
import java.net.SocketTimeoutException
import java.util.concurrent.TimeoutException

data class AppError(
    val code: AppErrorCode,
    val cause: Throwable? = null
)

val Throwable.asAppError: AppError
    get() = when (this) {
        is ConfigManagerException.RateLimit -> AppError(AppErrorCode.rateLimit, this)
        is GenericException -> AppError(AppErrorCode.other, this)
        is PartoutException -> asAppErrorFromPayload
        is ProfileImporterException.Binary -> AppError(AppErrorCode.binaryFile, this)
        is ProfileImporterException.Failure -> cause?.asAppError ?: AppError(AppErrorCode.importError, this)
        is ProfileImporterException.Null -> AppError(AppErrorCode.importError, this)
        is ProfileManagerException.NotFound -> AppError(AppErrorCode.notFound, this)
        is SecurityException -> AppError(AppErrorCode.permissionDenied, this)
        is SocketTimeoutException, is TimeoutException -> AppError(AppErrorCode.timeout, this)
        is TunnelObservableException.Generic -> AppError(AppErrorCode.other, this)
        is TunnelObservableException.Interactive -> AppError(AppErrorCode.interactiveLogin, this)
        is TunnelObservableException.VpnPermissionDenied -> AppError(AppErrorCode.permissionDenied, this)
        is VersionCheckerException.RateLimit -> AppError(AppErrorCode.rateLimit, this)
        is VersionCheckerException.UnexpectedResponse -> AppError(AppErrorCode.unexpectedResponse, this)
        else -> AppError(AppErrorCode.other, this)
    }

private val PartoutException.asAppErrorFromPayload: AppError
    get() {
        return when (payload?.code) {
            PartoutErrorCode.openVPNPassphraseRequired -> {
                AppError(AppErrorCode.openVPNPassphraseRequired)
            }
            PartoutErrorCode.openVPNUnsupportedCompression -> {
                AppError(AppErrorCode.openVPNUnsupportedCompression)
            }
            PartoutErrorCode.parsing -> {
                AppError(AppErrorCode.importError, this)
            }
            else -> AppError(AppErrorCode.partout, this)
        }
    }

fun AppErrorCode.Companion.fromLastErrorCode(string: String): AppErrorCode? {
    val comps = string.split(".")
    if (comps.count() != 2) { return null }
    if (comps[0] != "App") { return null }
    return AppErrorCode.decode(comps[1])
}

val AppErrorCode.toLastErrorCode: String
    get() = "App.$value"
