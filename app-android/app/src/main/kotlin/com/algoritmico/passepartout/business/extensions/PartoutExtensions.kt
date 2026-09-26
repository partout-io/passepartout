// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.extensions

import io.partout.models.OpenVPNErrorCode
import io.partout.models.PartoutErrorCode
import io.partout.models.PartoutErrorPair
import io.partout.models.TaggedProfile
import io.partout.models.WireGuardErrorCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive

val TaggedProfile.fingerprint: String?
    get() = (userInfo as? JsonObject)
        ?.get("fingerprint")
        ?.jsonPrimitive
        ?.content

fun PartoutErrorPair.Companion.openVPN(code: OpenVPNErrorCode): PartoutErrorPair =
    PartoutErrorPair(PartoutErrorCode.openVPN, code.value)

fun PartoutErrorPair.Companion.wireGuard(code: WireGuardErrorCode): PartoutErrorPair =
    PartoutErrorPair(PartoutErrorCode.wireGuard, code.value)
