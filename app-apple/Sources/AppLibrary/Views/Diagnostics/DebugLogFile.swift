// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI
import UniformTypeIdentifiers

struct DebugLogFile: Transferable {
    let lines: [String]

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .plainText) { log in
            SentTransferredFile(try log.writeToTemporaryURL())
        }
    }

    func writeToTemporaryURL() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(Strings.Unlocalized.debugLogFilename)
        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
