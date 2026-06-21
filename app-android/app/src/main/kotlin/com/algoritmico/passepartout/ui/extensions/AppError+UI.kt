// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.extensions

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.models.AppErrorCode
import com.algoritmico.passepartout.observables.AppError
import io.partout.models.PartoutErrorCode

// Map AppError.Code for ErrorHandler
@Composable
fun AppError.localizedMessage(): String {
    val detail = cause?.localizedMessage
    return when (code) {
        AppErrorCode.binaryFile -> stringResource(R.string.errors_app_import_binary)
        AppErrorCode.corruptProviderModule -> stringResource(
            R.string.errors_app_corrupt_provider_module,
            detail ?: "?"
        )
        AppErrorCode.couldNotLaunch -> detail ?: stringResource(R.string.errors_app_other)
        AppErrorCode.emptyProducts -> stringResource(R.string.errors_app_empty_products)
        AppErrorCode.emptyProfileName -> stringResource(R.string.errors_app_empty_profile_name)
        AppErrorCode.encoding -> detail ?: stringResource(R.string.errors_app_other)
        AppErrorCode.importError -> stringResource(R.string.errors_app_parsing)
            .appending(detail, separator = " ")
        AppErrorCode.incompatibleModules -> stringResource(R.string.errors_app_incompatible_modules)
        AppErrorCode.incompleteModule -> stringResource(
            R.string.errors_app_incomplete_module,
            stringResource(R.string.global_nouns_unknown)
        )
        AppErrorCode.invalidField -> stringResource(R.string.errors_app_invalid_fields)
        AppErrorCode.malformedModule -> stringResource(
            R.string.errors_app_malformed_module,
            stringResource(R.string.global_nouns_unknown),
            detail ?: "?"
        )
        AppErrorCode.missingProviderEntity -> stringResource(R.string.errors_app_missing_provider_entity)
        AppErrorCode.moduleRequiresConnection -> stringResource(
            R.string.errors_app_module_requires_connection,
            stringResource(R.string.global_nouns_unknown),
            "OpenVPN, WireGuard"
        )
        AppErrorCode.noActiveModules -> stringResource(R.string.errors_app_no_active_modules)
        AppErrorCode.openVPNUnsupportedCompression -> stringResource(
            R.string.errors_app_openvpn_unsupported_compression
        ).appending(detail, separator = "\n\n")
        AppErrorCode.other -> stringResource(R.string.errors_app_other)
            .appending(detail, separator = " ")
        AppErrorCode.partout -> stringResource(
            R.string.errors_app_partout,
            detail ?: "?"
        )
        AppErrorCode.permissionDenied -> stringResource(R.string.errors_app_permission_denied)
        AppErrorCode.timeout -> stringResource(R.string.errors_app_timeout)
        AppErrorCode.webReceiver -> stringResource(R.string.errors_app_web_receiver)
        AppErrorCode.wireGuardEmptyPeers -> stringResource(R.string.errors_app_wireguard_empty_peers)
        AppErrorCode.ineligibleProfile,
        AppErrorCode.interactiveLogin,
        AppErrorCode.notFound,
        AppErrorCode.openVPNPassphraseRequired,
        AppErrorCode.rateLimit,
        AppErrorCode.systemExtension,
        AppErrorCode.unexpectedResponse,
        AppErrorCode.urlRequestFailed,
        AppErrorCode.urlRequestUnavailable,
        AppErrorCode.verificationReceiptIsLoading,
        AppErrorCode.verificationRequiredFeatures,
        AppErrorCode.webUploader -> detail ?: stringResource(R.string.errors_app_other)
    }
}

// Map PartoutError.Code in the profile lastErrorCode text
@Composable
fun String.localizedStatusFromPartoutErrorCode(): String {
    val code = PartoutErrorCode.decode(this)
    return when (code) {
        PartoutErrorCode.authentication -> stringResource(R.string.errors_tunnel_auth)
        PartoutErrorCode.crypto -> stringResource(R.string.errors_tunnel_encryption)
        PartoutErrorCode.dnsFailure -> stringResource(R.string.errors_tunnel_dns)
        PartoutErrorCode.timeout -> stringResource(R.string.global_nouns_timeout)
        PartoutErrorCode.openVPNCompressionMismatch -> stringResource(R.string.errors_tunnel_compression)
        PartoutErrorCode.openVPNNoRouting -> stringResource(R.string.errors_tunnel_routing)
        PartoutErrorCode.openVPNRecoverableAuthentication -> stringResource(R.string.entities_tunnel_status_activating)
        PartoutErrorCode.openVPNServerShutdown -> stringResource(R.string.errors_tunnel_shutdown)
        PartoutErrorCode.openVPNTLSFailure -> stringResource(R.string.errors_tunnel_tls)
        else -> {
            // Custom app error codes from service
//            when (this) {
//                "App.ineligibleProfile" -> stringResource(R.string.errors_tunnel_ineligible)
//                else -> stringResource(R.string.errors_tunnel_generic)
//            }
            stringResource(R.string.errors_tunnel_generic)
        }
    }
}

private fun String.appending(optional: String?, separator: String): String {
    return listOfNotNull(this, optional)
        .filter { it.isNotBlank() }
        .joinToString(separator = separator)
}
