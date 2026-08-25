// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.extensions

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.business.extensions.JSON
import com.algoritmico.passepartout.models.AppErrorCode
import com.algoritmico.passepartout.observables.AppError
import com.algoritmico.passepartout.observables.fromLastErrorCode
import io.partout.abi.PartoutException
import io.partout.models.ModuleType
import io.partout.models.OpenVPNErrorCode
import io.partout.models.ParseErrorInfo
import io.partout.models.PartoutErrorCode
import io.partout.models.WireGuardErrorCode
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.decodeFromJsonElement

// Map AppError.Code for ErrorHandler
@Composable
fun AppError.localizedMessage(): String {
    val detail = cause?.localizedMessage
    return when (code) {
        AppErrorCode.binaryFile -> stringResource(R.string.errors_app_import_binary)
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
        AppErrorCode.moduleRequiresConnection -> stringResource(
            R.string.errors_app_module_requires_connection,
            stringResource(R.string.global_nouns_unknown),
            "OpenVPN, WireGuard"
        )
        AppErrorCode.noActiveModules -> stringResource(R.string.errors_app_no_active_modules)
        AppErrorCode.other -> stringResource(R.string.errors_app_other)
            .appending(detail, separator = " ")
        AppErrorCode.partout ->
            cause?.partoutDescription() ?: detail ?: stringResource(R.string.errors_app_partout)
        AppErrorCode.permissionDenied -> stringResource(R.string.errors_app_permission_denied)
        AppErrorCode.timeout -> stringResource(R.string.errors_app_timeout)
        AppErrorCode.webReceiver -> stringResource(R.string.errors_app_web_receiver)
        AppErrorCode.ineligibleProfile,
        AppErrorCode.interactiveLogin,
        AppErrorCode.notFound,
        AppErrorCode.rateLimit,
        AppErrorCode.systemExtension,
        AppErrorCode.unexpectedResponse,
        AppErrorCode.urlRequestFailed,
        AppErrorCode.urlRequestUnavailable,
        AppErrorCode.verificationReceiptIsLoading,
        AppErrorCode.verificationRequiredFeatures,
        AppErrorCode.webUploader -> detail ?: stringResource(R.string.errors_app_other)
        AppErrorCode.corruptProviderModule,
        AppErrorCode.missingProviderEntity,
        AppErrorCode.missingProviderOption,
        AppErrorCode.multipleTunnels -> error("Unimplemented")
        //
        AppErrorCode.openVPNPassphraseRequired,
        AppErrorCode.openVPNUnsupportedCompression,
        AppErrorCode.wireGuardEmptyPeers -> error("Deprecated")
    }
}

data class LocalizedConnectionStatusError(
    private val lastErrorCode: String
) {
    val localizedDescriptionResource: Int
        get() = AppErrorCode.fromLastErrorCode(lastErrorCode)?.localizedStatusResource
            ?: PartoutErrorCode.decode(lastErrorCode)?.localizedStatusResource
            ?: R.string.errors_tunnel_generic

    // Map error code in the ProfileRow lastErrorCode status text
    @Composable
    fun localizedDescription(): String {
        return stringResource(localizedDescriptionResource)
    }
}

private val AppErrorCode.localizedStatusResource: Int?
    get() = when (this) {
        AppErrorCode.ineligibleProfile -> R.string.errors_app_ineligible
        else -> null
    }

private val PartoutErrorCode.localizedStatusResource: Int?
    get() = when (this) {
        PartoutErrorCode.authentication -> R.string.errors_tunnel_auth
        PartoutErrorCode.crypto -> R.string.errors_tunnel_encryption
        PartoutErrorCode.dnsFailure -> R.string.errors_tunnel_dns
        PartoutErrorCode.timeout -> R.string.global_nouns_timeout
        PartoutErrorCode.openVPNCompressionMismatch -> R.string.errors_tunnel_compression
        PartoutErrorCode.openVPNNoRouting -> R.string.errors_tunnel_routing
        PartoutErrorCode.openVPNRecoverableAuthentication -> R.string.entities_tunnel_status_activating
        PartoutErrorCode.openVPNServerShutdown -> R.string.errors_tunnel_shutdown
        PartoutErrorCode.openVPNTLSFailure -> R.string.errors_tunnel_tls
        else -> null
    }

private fun String.appending(optional: String?, separator: String): String {
    return listOfNotNull(this, optional)
        .filter { it.isNotBlank() }
        .joinToString(separator = separator)
}

@Composable
fun Throwable.partoutDescription(): String? {
    if (this !is PartoutException) return null
    return when (code) {
        PartoutErrorCode.parsing -> parsingDescription()
        else -> null
    } ?: "${code.value}, payload=${JSON.encodeElement(payload)}"
}

@Composable
fun PartoutException.parsingDescription(): String? {
    return payload?.let { payload ->
        val info = runCatching {
            Json.decodeFromJsonElement<ParseErrorInfo>(payload)
        }.getOrNull() ?: return null
        val argument = info.arguments.firstOrNull()
        return when (info.recognizedType) {
            ModuleType.OpenVPN -> {
                when (OpenVPNErrorCode.decode(info.subCode)) {
                    OpenVPNErrorCode.unsupportedCompression -> stringResource(
                        R.string.errors_openvpn_unsupported_compression
                    )
                    else -> null
                }
            }
            ModuleType.WireGuard -> {
                when (WireGuardErrorCode.decode(info.subCode)) {
                    WireGuardErrorCode.emptyPeers -> stringResource(
                        R.string.errors_wireguard_empty_peers
                    )
                    WireGuardErrorCode.interfaceHasInvalidAddress -> stringResource(
                        R.string.errors_wireguard_interface_address_invalid,
                        argument ?: return null
                    )
                    WireGuardErrorCode.interfaceHasInvalidDNS -> stringResource(
                        R.string.errors_wireguard_interface_dns_invalid,
                        argument ?: return null
                    )
                    WireGuardErrorCode.interfaceHasInvalidListenPort -> stringResource(
                        R.string.errors_wireguard_interface_listen_port_invalid,
                        argument ?: return null
                    )
                    WireGuardErrorCode.interfaceHasInvalidMTU -> stringResource(
                        R.string.errors_wireguard_interface_mtu_invalid,
                        argument ?: return null
                    )
                    WireGuardErrorCode.interfaceHasInvalidPrivateKey -> stringResource(
                        R.string.errors_wireguard_interface_private_key_invalid
                    )
                    WireGuardErrorCode.interfaceHasNoPrivateKey -> stringResource(
                        R.string.errors_wireguard_interface_private_key_required
                    )
                    WireGuardErrorCode.interfaceHasUnrecognizedKey -> stringResource(
                        R.string.errors_wireguard_interface_unrecognized_key,
                        argument ?: return null
                    )
                    WireGuardErrorCode.multipleEntriesForKey -> stringResource(
                        R.string.errors_wireguard_multiple_entries_for_key,
                        argument ?: return null
                    )
                    WireGuardErrorCode.multipleInterfaces -> stringResource(
                        R.string.errors_wireguard_multiple_interfaces
                    )
                    WireGuardErrorCode.multiplePeersWithSamePublicKey -> stringResource(
                        R.string.errors_wireguard_peer_public_key_duplicated
                    )
                    WireGuardErrorCode.noInterface -> stringResource(
                        R.string.errors_wireguard_no_interface
                    )
                    WireGuardErrorCode.peerHasInvalidAllowedIP -> stringResource(
                        R.string.errors_wireguard_peer_allowed_ips_invalid,
                        argument ?: return null
                    )
                    WireGuardErrorCode.peerHasInvalidEndpoint -> stringResource(
                        R.string.errors_wireguard_peer_endpoint_invalid,
                        argument ?: return null
                    )
                    WireGuardErrorCode.peerHasInvalidPersistentKeepAlive -> stringResource(
                        R.string.errors_wireguard_peer_persistent_keepalive_invalid,
                        argument ?: return null
                    )
                    WireGuardErrorCode.peerHasInvalidPreSharedKey -> stringResource(
                        R.string.errors_wireguard_peer_pre_shared_key_invalid
                    )
                    WireGuardErrorCode.peerHasInvalidPublicKey -> stringResource(
                        R.string.errors_wireguard_peer_public_key_invalid
                    )
                    WireGuardErrorCode.peerHasNoPublicKey -> stringResource(
                        R.string.errors_wireguard_peer_public_key_required
                    )
                    WireGuardErrorCode.peerHasUnrecognizedKey -> stringResource(
                        R.string.errors_wireguard_peer_unrecognized_key,
                        argument ?: return null
                    )
                    else -> null
                }
            }
            else -> null
        }
    }
}
