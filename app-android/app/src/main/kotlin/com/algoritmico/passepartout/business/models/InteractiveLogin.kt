// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.models

import io.partout.extensions.interactiveModule
import io.partout.extensions.withInteractiveLogin
import io.partout.models.OpenVPNCredentialsOTPMethod
import io.partout.models.TaggedModuleOpenVPN
import io.partout.models.TaggedProfile

/** Input for one connection attempt; never saved to the profile repository. */
class InteractiveLogin(val original: TaggedProfile) {
    private val saved = (original.interactiveModule as? TaggedModuleOpenVPN)?.value?.credentials
    val needsOTP = saved?.otpMethod?.let { it != OpenVPNCredentialsOTPMethod.none } ?: false
    var username: String = saved?.username.orEmpty()
    // Carries the raw OTP when needsOTP is true.
    var password: String = ""

    fun connectionProfile(): TaggedProfile = original.withInteractiveLogin(
        username = username,
        password = password,
        otp = if (needsOTP) password else null
    )
}
