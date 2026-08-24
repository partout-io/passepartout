// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Partout
import Testing

struct LoggingTests {
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
