// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi

import io.partout.abi.TaggedProfile

interface AppABITunnelProtocol {
    suspend fun connect(profile: TaggedProfile)
    suspend fun disconnect(profileId: String)
}
