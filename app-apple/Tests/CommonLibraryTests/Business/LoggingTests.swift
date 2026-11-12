// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Partout
import Testing

struct LoggingTests {
    @Test
    func givenNativeConnectionRecord_whenFormatting_thenPreservesItsIdentity() {
        let message = "[ABCDEF12] Connected"
        #expect(tunnelLogMessage(.global, message) == message)
        #expect(tunnelLogMessage(.global, "Initialized") == "[GLOBAL] Initialized")
        #expect(tunnelLogMessage(.global, "[OpenVPN] Initialized") == "[GLOBAL] [OpenVPN] Initialized")
        let context = PartoutLoggerContext(Profile.ID(uuidString: "12345678-1111-1111-1111-111111111111")!)
        #expect(tunnelLogMessage(context, "Connected") == "[12345678] Connected")
        #expect(tunnelLogMessage(context, message) == message)
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
