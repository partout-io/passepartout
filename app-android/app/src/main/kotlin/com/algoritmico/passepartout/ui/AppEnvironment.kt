// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

import androidx.compose.runtime.staticCompositionLocalOf
import com.algoritmico.passepartout.context.AndroidConstants
import com.algoritmico.passepartout.models.AppConfiguration
import com.algoritmico.passepartout.observables.ConfigObservable
import com.algoritmico.passepartout.observables.DiagnosticsObservable
import com.algoritmico.passepartout.observables.ErrorHandler
import com.algoritmico.passepartout.observables.ProfileObservable
import com.algoritmico.passepartout.observables.TunnelObservable
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import com.algoritmico.passepartout.observables.VersionObservable

val LocalAppConfiguration = staticCompositionLocalOf<AppConfiguration> {
    error("No AppConfiguration provided")
}

val LocalAndroidConstants = staticCompositionLocalOf<AndroidConstants> {
    error("No AndroidConstants provided")
}

val LocalConfigObservable = staticCompositionLocalOf<ConfigObservable> {
    error("No ConfigObservable provided")
}

val LocalDiagnosticsObservable = staticCompositionLocalOf<DiagnosticsObservable> {
    error("No DiagnosticsObservable provided")
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
