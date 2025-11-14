// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public struct AppProfile: Identifiable, Hashable, Sendable {
    public private(set) var header: AppProfileHeader
    public let native: Profile

    public var id: AppIdentifier {
        native.id
    }

    public init(header: AppProfileHeader, native: Profile) {
        self.header = header
        self.native = native
    }
}
