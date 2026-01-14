// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import MiniFoundation

extension ABI {
    public struct WebsiteWithPasscode: Sendable {
        public let url: URL

        public let passcode: String?
    }

    public struct WebFileUpload: Sendable {
        public let name: String

        public let contents: String
    }
}
