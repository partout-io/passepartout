// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppLibrary
import CommonLibrary
import Foundation
import Testing

@MainActor
struct UserPreferencesLoggingTests {
    @Test
    func givenVerbosityChange_whenSettingPreference_thenNotifiesAfterPersisting() throws {
        let preferences = AppPreferencesStore()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let sut = UserPreferencesObservable(preferences: preferences, ui: defaults)
        var changes: [Bool] = []
        sut.onLogLevelChange = { changes.append(preferences[\.extensiveLogging]) }
        sut.extensiveLogging = true
        sut.extensiveLogging = false
        sut.extensiveLogging = false
        #expect(changes == [true, false])
    }

    @Test
    func givenPrivacyChange_whenSettingPreference_thenNotifiesAfterPersisting() throws {
        let preferences = AppPreferencesStore()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let sut = UserPreferencesObservable(preferences: preferences, ui: defaults)
        var changes: [Bool] = []
        sut.onLogPrivacyChange = { changes.append(preferences[\.logsPrivateData]) }
        sut.logsPrivateData = true
        sut.logsPrivateData = false
        sut.logsPrivateData = false
        #expect(changes == [true, false])
    }
}
