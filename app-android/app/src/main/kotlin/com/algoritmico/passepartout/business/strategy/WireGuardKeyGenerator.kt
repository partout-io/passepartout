// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.strategy

/** WireGuard keys use Base64 encoding, matching Partout and the profile schema. */
interface WireGuardKeyGenerator {
    /** Returns null if key generation fails. */
    fun newPrivateKey(): String?

    /** Returns null if the private key is invalid or derivation fails. */
    fun publicKey(privateKey: String): String?
}
