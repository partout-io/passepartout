// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.extensions

import com.algoritmico.passepartout.models.SemanticVersion

val SemanticVersion.versionString: String
    get() = "$major.$minor.$patch"

val SemanticVersion.Companion.max: SemanticVersion
    get() = SemanticVersion(255, 255, 255)

fun String.toSemanticVersionOrNull(): SemanticVersion? {
    return runCatching {
        val parts = split(".")
        require(parts.size == 3)
        val major = parts[0].toInt()
        val minor = parts[1].toInt()
        val patch = parts[2].toInt()
        SemanticVersion(major, minor, patch)
    }.getOrNull()
}
