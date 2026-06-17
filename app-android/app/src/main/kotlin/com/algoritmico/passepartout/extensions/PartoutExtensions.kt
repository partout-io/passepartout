// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.extensions

import io.partout.models.TaggedProfile
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive

val TaggedProfile.fingerprint: String?
    get() = (userInfo as? JsonObject)
        ?.get("fingerprint")
        ?.jsonPrimitive
        ?.content
