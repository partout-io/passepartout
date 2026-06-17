// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.extensions

import com.algoritmico.passepartout.models.SemanticVersion

val SemanticVersion.versionString: String
    get() = "$major.$minor.$patch"
