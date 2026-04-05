// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ModuleShareButton: View {
    private let file: SerializedModuleFile

    public init(file: SerializedModuleFile) {
        self.file = file
    }

    public var body: some View {
        ShareLink(
            item: SerializedModuleRepresentation(file: file),
            preview: SharePreview(file.name),
            label: {
                Text(Strings.Global.Actions.share)
            }
        )
    }
}

private struct SerializedModuleRepresentation: Transferable {
    let file: SerializedModuleFile

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { subject in
            let url = FileManager.default.makeTemporaryURL(filename: subject.file.filename)
            try subject.file.content.write(to: url, atomically: true, encoding: .utf8)
            return url
        }
    }
}
