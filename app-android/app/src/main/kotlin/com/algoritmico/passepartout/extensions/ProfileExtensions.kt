// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.extensions

import io.partout.models.OpenVPNCredentials
import io.partout.models.OpenVPNCredentialsOTPMethod
import io.partout.models.OpenVPNModule
import io.partout.models.TaggedModuleOpenVPN
import io.partout.models.TaggedProfile
import java.util.Base64

val TaggedProfile.isInteractive: Boolean
    get() = interactiveOpenVPNModule != null

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

private val OpenVPNModule.isInteractive: Boolean
    get() {
        if (requiresCredentials) {
            return true
        }
        return configuration?.staticChallenge == true ||
            requiresInteractiveCredentials == true
    }

private val OpenVPNModule.requiresCredentials: Boolean
    get() = configuration?.authUserPass == true &&
        (credentials?.isEmpty ?: true)

private val OpenVPNCredentials.isEmpty: Boolean
    get() = username.isEmpty() && password.isEmpty()

private fun OpenVPNCredentialsOTPMethod.encodedPassword(
    password: String,
    otp: String
): String {
    return when (this) {
        OpenVPNCredentialsOTPMethod.none -> password
        OpenVPNCredentialsOTPMethod.append -> password + otp
        OpenVPNCredentialsOTPMethod.encode -> {
            val base64Password = Base64.getEncoder().encodeToString(password.toByteArray(Charsets.UTF_8))
            val base64OTP = Base64.getEncoder().encodeToString(otp.toByteArray(Charsets.UTF_8))
            "SCRV1:$base64Password:$base64OTP"
        }
    }
}
