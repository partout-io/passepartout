// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public struct MigratableProfile: Identifiable, Sendable {
    public let id: UUID

    public let name: String

    public let lastUpdate: Date?

    public init(id: UUID, name: String, lastUpdate: Date?) {
        self.id = id
        self.name = name
        self.lastUpdate = lastUpdate
    }
}

extension MigratableProfile: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
