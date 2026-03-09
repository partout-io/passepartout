// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public struct WebsiteWithPasscode: Equatable, Codable, Sendable {
        public let url: URL

        public let passcode: String?
    }

    public struct WebFileUpload: Equatable, Codable, Sendable {
        public let name: String

        public let contents: String
    }
}
