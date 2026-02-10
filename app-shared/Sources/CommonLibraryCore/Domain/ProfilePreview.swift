// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    @available(*, deprecated, message: "#1680, Use AppProfileHeader?")
    public struct ProfilePreview: Identifiable, Hashable, Sendable {
        public let id: Profile.ID

        public let name: String

        public let subtitle: String?

        public init(id: Profile.ID, name: String, subtitle: String? = nil) {
            self.id = id
            self.name = name
            self.subtitle = subtitle
        }

        public init(_ profile: Profile) {
            id = profile.id
            name = profile.name
            subtitle = nil
        }
    }
}
