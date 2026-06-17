// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.extensions

import io.partout.extensions.encodedPassword
import io.partout.extensions.isInteractive
import io.partout.models.OpenVPNCredentials
import io.partout.models.OpenVPNCredentialsOTPMethod
import io.partout.models.OpenVPNModule
import io.partout.models.TaggedModuleOpenVPN
import io.partout.models.TaggedProfile
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive

val TaggedProfile.fingerprint: String?
    get() = (userInfo as? JsonObject)
        ?.get("fingerprint")
        ?.jsonPrimitive
        ?.content

val TaggedProfile.interactiveOpenVPNModule: OpenVPNModule?
    get() = modules.firstNotNullOfOrNull { module ->
        val openVPNModule = (module as? TaggedModuleOpenVPN)?.value
        openVPNModule?.takeIf {
            it.id in activeModulesIds && it.isInteractive
        }
    }

fun TaggedProfile.withInteractiveOpenVPNCredentials(
    username: String,
    password: String,
    otp: String? = null
): TaggedProfile {
    val interactiveModule = interactiveOpenVPNModule ?: return this
    val existingCredentials = interactiveModule.credentials
    val otpMethod = existingCredentials?.otpMethod ?: OpenVPNCredentialsOTPMethod.none
    val credentialUsername = if (otpMethod == OpenVPNCredentialsOTPMethod.none) {
        username
    } else {
        existingCredentials?.username.orEmpty()
    }
    val credentialPassword = if (otpMethod == OpenVPNCredentialsOTPMethod.none) {
        password
    } else {
        otpMethod.encodedPassword(
            password = existingCredentials?.password.orEmpty(),
            otp = otp.orEmpty()
        )
    }
    val credentials = OpenVPNCredentials(
        otpMethod = OpenVPNCredentialsOTPMethod.none,
        password = credentialPassword,
        username = credentialUsername
    )
    return copy(
        modules = modules.map { module ->
            if (module is TaggedModuleOpenVPN && module.value.id == interactiveModule.id) {
                module.copy(
                    value = module.value.copy(
                        credentials = credentials
                    )
                )
            } else {
                module
            }
        }
    )
}
