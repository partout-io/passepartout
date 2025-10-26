// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public struct ProviderCache: Hashable, Codable, Sendable {
    public let lastUpdate: Timestamp?

    public let tag: String?

    public init(lastUpdate: Timestamp?, tag: String?) {
        self.lastUpdate = lastUpdate
        self.tag = tag
    }
}
