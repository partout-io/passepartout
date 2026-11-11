// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Partout
import Testing

struct LoggingTests {
    @Test
    func givenNativeConnectionRecord_whenFormatting_thenPreservesItsIdentity() {
        let message = "[profile=11111111-1111-1111-1111-111111111111 module=22222222-2222-2222-2222-222222222222] Connected"
        #expect(tunnelLogMessage(.global, message) == message)
        #expect(tunnelLogMessage(.global, "Initialized") == "[GLOBAL] Initialized")
    }

    @Test
    func givenPrivateDataPreference_whenConfigureLogging_thenEnablesSensitiveValues() {
        var preferences = ABI.AppPreferences.default()
        preferences.logsPrivateData = true
        var sut = PartoutLogger.Builder()

        sut.configureLogging(
            preferences: AppPreferencesStore(preferences),
            parameters: .init(
                tag: "tests",
                formatter: .init(timestamp: "", message: ""),
                sinceLast: 0,
                options: .init(
                    maxLevel: .debug,
                    maxSize: 0,
                    maxBufferedLines: 0
                ),
                filenames: .init(app: "", tunnel: "")
            ),
            localURL: nil,
            localMapper: nil
        )

        #expect(sut.logsAddresses)
        #expect(sut.logsModules)
        #expect(!sut.logsRawBytes)
    }
}
