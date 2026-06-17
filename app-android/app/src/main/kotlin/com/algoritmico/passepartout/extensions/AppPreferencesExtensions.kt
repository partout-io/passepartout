// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.extensions

import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.models.ConfigFlag
import com.algoritmico.passepartout.models.ExperimentalPreferences

fun AppPreferences.isFlagEnabled(flag: ConfigFlag): Boolean {
    return (configFlags.contains(flag) || experimental.enabledConfigFlags.contains(flag)) &&
        !experimental.ignoredConfigFlags.contains(flag)
}

fun ExperimentalPreferences.isAllowed(flag: ConfigFlag): Boolean {
    return !ignoredConfigFlags.contains(flag)
}

fun ExperimentalPreferences.setAllowed(
    flag: ConfigFlag,
    isAllowed: Boolean
): ExperimentalPreferences {
    return if (isAllowed) {
        unignore(flag)
    } else {
        ignore(flag)
    }
}

fun ExperimentalPreferences.ignore(flag: ConfigFlag): ExperimentalPreferences {
    return copy(
        ignoredConfigFlags = ignoredConfigFlags.adding(flag)
    )
}

fun ExperimentalPreferences.unignore(flag: ConfigFlag): ExperimentalPreferences {
    return copy(
        ignoredConfigFlags = ignoredConfigFlags.removing(flag)
    )
}

fun ExperimentalPreferences.enable(flag: ConfigFlag): ExperimentalPreferences {
    return copy(
        enabledConfigFlags = enabledConfigFlags.adding(flag)
    )
}

fun ExperimentalPreferences.disable(flag: ConfigFlag): ExperimentalPreferences {
    return copy(
        enabledConfigFlags = enabledConfigFlags.removing(flag)
    )
}

private fun List<ConfigFlag>.adding(flag: ConfigFlag): List<ConfigFlag> {
    return if (contains(flag)) {
        this
    } else {
        this + flag
    }
}

private fun List<ConfigFlag>.removing(flag: ConfigFlag): List<ConfigFlag> {
    return filterNot { it == flag }
}

val AppPreferences.Companion.default: AppPreferences
    get() = AppPreferences(
        configFlags = listOf(),
        dnsFallsBack = true,
        experimental = ExperimentalPreferences(listOf(), listOf()),
        extensiveLogging = false,
        logsPrivateData = false,
        newProfileEncoding = false,
        relaxedVerification = false,
        skipsPurchases = false
    )

fun AppPreferences.update(
    new: AppPreferences,
    fields: List<AppPreferenceKey>
): AppPreferences {
    var updated = this
    fields.forEach {
        updated = when (it) {
            AppPreferenceKey.deviceId -> updated.copy(
                deviceId = new.deviceId
            )
            AppPreferenceKey.configFlags -> updated.copy(
                configFlags = new.configFlags
            )
            AppPreferenceKey.dnsFallsBack -> updated.copy(
                dnsFallsBack = new.dnsFallsBack
            )
            AppPreferenceKey.experimental -> updated.copy(
                experimental = new.experimental
            )
            AppPreferenceKey.extensiveLogging -> updated.copy(
                extensiveLogging = new.extensiveLogging
            )
            AppPreferenceKey.lastCheckedVersion -> updated.copy(
                lastCheckedVersion = new.lastCheckedVersion
            )
            AppPreferenceKey.lastCheckedVersionDate -> updated.copy(
                lastCheckedVersionTimestamp = new.lastCheckedVersionTimestamp
            )
            AppPreferenceKey.lastUsedProfileId -> updated.copy(
                lastUsedProfileUUID = new.lastUsedProfileUUID
            )
            AppPreferenceKey.logsPrivateData -> updated.copy(
                logsPrivateData = new.logsPrivateData
            )
            AppPreferenceKey.newProfileEncoding -> updated.copy(
                newProfileEncoding = new.newProfileEncoding
            )
            AppPreferenceKey.relaxedVerification -> updated.copy(
                relaxedVerification = new.relaxedVerification
            )
            AppPreferenceKey.skipsPurchases -> updated.copy(
                skipsPurchases = new.skipsPurchases
            )
        }
    }
    return updated
}