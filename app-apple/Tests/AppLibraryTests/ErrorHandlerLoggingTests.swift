// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
import CommonLibrary
import Partout
import Testing

@MainActor
@Suite(.serialized)
struct ErrorHandlerLoggingTests {
    @Test(arguments: [false, true])
    func alertLogFollowsPreferenceWhileUIDetailRemainsAvailable(logsPrivateData: Bool) throws {
        let previous = PartoutLogger.default
        defer { PartoutLogger.register(previous) }
        var builder = PartoutLogger.Builder()
        builder.logsModules = logsPrivateData
        builder.setLocalLogger(
            url: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            options: .init(maxLevel: .debug, maxSize: 1_000_000, maxBufferedLines: 100),
            mapper: { $0.message }
        )
        let logger = builder.build()
        PartoutLogger.register(logger)

        let reason = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "private-ui-detail"])
        let error = ABI.AppError.encoding(reason: reason)
        #expect(error.localizedDescription(style: .errorHandler) == "private-ui-detail")
        ErrorHandler.default().handle(error, message: "private-profile-name")

        let line = try #require(logger.currentLog(sinceLast: 60, maxLevel: .debug).last)
        #expect(line.contains("private-ui-detail") == logsPrivateData)
        #expect(line.contains("private-profile-name") == logsPrivateData)
    }
}
