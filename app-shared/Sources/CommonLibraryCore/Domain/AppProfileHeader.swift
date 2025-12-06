// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public struct AppProfileHeader: Identifiable, Hashable, Comparable, Sendable {
        public private(set) var id: AppIdentifier
        public let name: String
        public let moduleTypes: [String]
        public let fingerprint: String
        public let sharingFlags: [ProfileSharingFlag]
        public let requiredFeatures: Set<AppFeature>

        public init(id: AppIdentifier, name: String, moduleTypes: [String], fingerprint: String, sharingFlags: [ProfileSharingFlag], requiredFeatures: Set<AppFeature>) {
            self.id = id
            self.name = name
            self.moduleTypes = moduleTypes
            self.fingerprint = fingerprint
            self.sharingFlags = sharingFlags
            self.requiredFeatures = requiredFeatures
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.name.lowercased() < rhs.name.lowercased()
        }
    }
}
