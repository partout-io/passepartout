// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public struct SerializedModuleFile: Sendable {
    public let name: String

    public let `extension`: String

    public let content: String

    public var filename: String {
        let suffix = ".\(`extension`)"
        guard !name.hasSuffix(suffix) else { return name }
        return "\(name)\(suffix)"
    }
}
