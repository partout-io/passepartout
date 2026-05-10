// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.helpers

import io.partout.abi.TaggedProfile

interface AppABIProfileProtocol {
    suspend fun importText(text: String, filename: String)
    suspend fun remove(profileId: String)
    suspend fun remove(profileIds: Collection<String>)
    fun profile(profileId: String): TaggedProfile?
}
