package com.algoritmico.passepartout.extensions

import com.algoritmico.passepartout.models.AppProfileStatus
import com.algoritmico.passepartout.models.ProfileTransfer
import io.partout.extensions.encodedPassword
import io.partout.extensions.isInteractive
import io.partout.models.OpenVPNCredentials
import io.partout.models.OpenVPNCredentialsOTPMethod
import io.partout.models.OpenVPNModule
import io.partout.models.TaggedModuleOpenVPN
import io.partout.models.TaggedProfile
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.util.Locale

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

fun AppProfileStatus.statusText(): String {
    return when (this) {
        AppProfileStatus.disconnected -> "Inactive"
        AppProfileStatus.connecting -> "Activating"
        AppProfileStatus.connected -> "Active"
        AppProfileStatus.disconnecting -> "Deactivating"
    }
}

fun ProfileTransfer.transferText(): String {
    return "↓${received.toLong().formatDataUnit()} ↑${sent.toLong().formatDataUnit()}"
}

private fun Long.formatDataUnit(): String {
    val value = coerceAtLeast(0L)
    if (value == 0L) {
        return "0B"
    }
    if (value < KILOBYTE) {
        return "${value}B"
    }
    return when {
        value >= GIGABYTE / 10L -> value.formatDecimalDataUnit(GIGABYTE, "GB")
        value >= MEGABYTE / 10L -> value.formatDecimalDataUnit(MEGABYTE, "MB")
        else -> "${value / KILOBYTE}kB"
    }
}

private fun Long.formatDecimalDataUnit(unitSize: Long, unit: String): String {
    val count = toDouble() / unitSize.toDouble()
    return String.format(Locale.US, "%.2f%s", count, unit)
}

private const val KILOBYTE = 1024L
private const val MEGABYTE = KILOBYTE * 1024L
private const val GIGABYTE = MEGABYTE * 1024L
