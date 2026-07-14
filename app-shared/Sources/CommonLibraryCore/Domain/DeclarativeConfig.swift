// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public struct DeclarativeConfig: Codable, Sendable {
    public var app: ABI.AppPreferences?
    public var profiles: [TaggedProfile]?

    public init(app: ABI.AppPreferences? = nil, profiles: [TaggedProfile]? = nil) {
        self.app = app
        self.profiles = profiles
    }
}
