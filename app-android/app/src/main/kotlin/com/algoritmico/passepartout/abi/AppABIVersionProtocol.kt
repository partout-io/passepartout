// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi

import com.algoritmico.passepartout.abi.models.ChangelogEntry

interface AppABIVersionProtocol {
    suspend fun fetchChangelog(version: String): List<ChangelogEntry>
}
