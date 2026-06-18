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

val LocalProfileObservable = staticCompositionLocalOf<ProfileObservable> {
    error("No ProfileObservable provided")
}

val LocalTunnelObservable = staticCompositionLocalOf<TunnelObservable> {
    error("No TunnelObservable provided")
}

val LocalUserPreferencesObservable = staticCompositionLocalOf<UserPreferencesObservable> {
    error("No UserPreferencesObservable provided")
}

val LocalVersionObservable = staticCompositionLocalOf<VersionObservable> {
    error("No VersionObservable provided")
}

val LocalErrorHandler = staticCompositionLocalOf<ErrorHandler> {
    error("No ErrorHandler provided")
}
