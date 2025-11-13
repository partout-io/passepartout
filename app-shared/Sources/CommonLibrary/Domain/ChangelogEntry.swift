// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public struct ChangelogEntry {
    public let id: Int

    public let comment: String

    public let issue: Int?

    public init(_ id: Int, _ comment: String, _ issue: Int?) {
        self.id = id
        self.comment = comment
        self.issue = issue
    }
}
