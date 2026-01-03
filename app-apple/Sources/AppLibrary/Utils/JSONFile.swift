// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI
import UniformTypeIdentifiers

public struct JSONFile: FileDocument {
    public static let readableContentTypes: [UTType] = [.json]

    private var string = ""

    public init(string: String = "") {
        self.string = string
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { return }
        string = String(decoding: data, as: UTF8.self)
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(string.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

#endif
