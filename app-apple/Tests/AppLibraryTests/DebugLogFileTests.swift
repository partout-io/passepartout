// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
import Foundation
import Testing

struct DebugLogFileTests {
    @Test
    func givenLogSnapshots_whenExporting_thenReplacesPreviousTextFile() throws {
        let first = DebugLogFile(lines: ["First log: café 日本語", "", "Last line"])
        let second = DebugLogFile(lines: ["Another log"])
        let firstURL = try first.writeToTemporaryURL()
        defer { try? FileManager.default.removeItem(at: firstURL) }
        #expect(firstURL.lastPathComponent == "debug-log.txt")
        #expect(try String(contentsOf: firstURL, encoding: .utf8) == first.lines.joined(separator: "\n"))

        let secondURL = try second.writeToTemporaryURL()
        #expect(firstURL == secondURL)
        #expect(try String(contentsOf: secondURL, encoding: .utf8) == "Another log")
    }
}
