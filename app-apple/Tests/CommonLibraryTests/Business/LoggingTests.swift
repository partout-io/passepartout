// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Partout
import Testing

struct LoggingTests {
    @Test
    func givenLogContext_whenFormatting_thenUsesOnlyItsProfileIdentity() {
        #expect(tunnelLogMessage(.global, "Initialized") == "[GLOBAL] Initialized")
        let context = PartoutLoggerContext(Profile.ID(uuidString: "abcdef12-1111-1111-1111-111111111111")!)
        #expect(tunnelLogMessage(context, "Connected") == "[ABCDEF12] Connected")
        // Message text cannot impersonate record context.
        #expect(tunnelLogMessage(.global, "[ABCDEF12] Connected") == "[GLOBAL] [ABCDEF12] Connected")
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
