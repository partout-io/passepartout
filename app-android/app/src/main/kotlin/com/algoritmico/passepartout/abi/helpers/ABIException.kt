// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi.helpers

class ABIException(
    val code: Int,
    val payload: String?
) : RuntimeException("ABI call failed (code=$code): $payload")
