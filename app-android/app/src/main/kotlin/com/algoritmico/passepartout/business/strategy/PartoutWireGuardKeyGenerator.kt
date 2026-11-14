// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.strategy

import io.partout.PartoutWrapper

class PartoutWireGuardKeyGenerator(private val library: PartoutWrapper) : WireGuardKeyGenerator {
    override fun newPrivateKey(): String? = library.partoutWireGuardGenKey()

    override fun publicKey(privateKey: String): String? = library.partoutWireGuardPubKey(privateKey)
}
