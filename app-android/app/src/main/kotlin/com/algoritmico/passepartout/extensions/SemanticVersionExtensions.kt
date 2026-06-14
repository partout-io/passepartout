// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.extensions

import com.algoritmico.passepartout.abi.models.SemanticVersion

val SemanticVersion.versionString: String
    get() = "$major.$minor.$patch"
