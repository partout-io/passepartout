// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi

import com.algoritmico.passepartout.abi.models.AppPreferences

interface AppABIKeyStoreProtocol {
    fun set(preferences: AppPreferences)
}
