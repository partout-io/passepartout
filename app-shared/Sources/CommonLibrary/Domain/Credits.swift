// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public struct Credits: Decodable {
    public struct License: Decodable {
        public let name: String

        public let licenseName: String

        public let licenseURL: URL
    }

    public struct Notice: Decodable {
        public let name: String

        public let message: String
    }

    public let licenses: [License]

    public let notices: [Notice]

    public let translations: [String: [String]]
}
