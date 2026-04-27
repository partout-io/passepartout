// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
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
}
