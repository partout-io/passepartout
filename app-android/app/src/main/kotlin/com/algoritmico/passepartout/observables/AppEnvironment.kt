// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import androidx.compose.runtime.staticCompositionLocalOf
import com.algoritmico.passepartout.models.AppConfiguration

val LocalAppConfiguration = staticCompositionLocalOf<AppConfiguration> {
    error("No AppConfiguration provided")
}

val LocalConfigObservable = staticCompositionLocalOf<ConfigObservable> {
    error("No ConfigObservable provided")
}

val LocalVersionObservable = staticCompositionLocalOf<VersionObservable> {
    error("No VersionObservable provided")
}
