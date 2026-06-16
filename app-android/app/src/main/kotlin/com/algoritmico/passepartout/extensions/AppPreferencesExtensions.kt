// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.extensions

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
