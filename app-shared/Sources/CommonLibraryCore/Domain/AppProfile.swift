// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public struct AppProfileHeader: Identifiable, Hashable, Comparable, Sendable {
        public private(set) var id: Profile.ID
        public let name: String
        public let subtitle: String?
        public let moduleTypes: [String]
        public let fingerprint: String
        public let sharingFlags: [ProfileSharingFlag]
        public let requiredFeatures: Set<AppFeature>

        public init(id: Profile.ID, name: String, subtitle: String?, moduleTypes: [String], fingerprint: String, sharingFlags: [ProfileSharingFlag], requiredFeatures: Set<AppFeature>) {
            self.id = id
            self.name = name
            self.subtitle = subtitle
            self.moduleTypes = moduleTypes
            self.fingerprint = fingerprint
            self.sharingFlags = sharingFlags
            self.requiredFeatures = requiredFeatures
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.name.lowercased() < rhs.name.lowercased()
        }
    }

    public enum AppProfileStatus: Int, Codable, Sendable {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }

    public struct AppProfileInfo: Identifiable, Hashable, Codable, Sendable {
        public let id: Profile.ID
        public let status: AppProfileStatus
        public let onDemand: Bool

        public init(id: Profile.ID, status: AppProfileStatus, onDemand: Bool) {
            self.id = id
            self.status = status
            self.onDemand = onDemand
        }
    }
}
