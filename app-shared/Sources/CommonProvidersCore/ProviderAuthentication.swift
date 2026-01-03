// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// treat as a "C union"
public struct ProviderAuthentication: Hashable, Codable, Sendable {
    public struct Credentials: Hashable, Codable, Sendable {
        public var username: String

        public var password: String

        public init(username: String = "", password: String = "") {
            self.username = username
            self.password = password
        }
    }

    public struct Token: Hashable, Codable, Sendable {
        public let accessToken: String

        public let expiryDate: Date

        public init(accessToken: String, expiryDate: Date) {
            self.accessToken = accessToken
            self.expiryDate = expiryDate
        }
    }

    public var credentials: Credentials?

    public var token: Token?

    public init() {
    }

    public var isEmpty: Bool {
        credentials == nil && token == nil
    }
}
