// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.strategy

interface WireGuardKeyGenerator {
    fun newPrivateKey(): String?
    fun publicKey(privateKey: String): String?
}
