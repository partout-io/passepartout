// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension ABI {
    public enum ProfileSharingFlag: String, Codable, Sendable {
        case shared
        case tv
    }

    public struct ProfileHeader: Identifiable, Hashable, Comparable, Sendable, DTO {
        public private(set) var id: Identifier
        public let name: String
        public let moduleTypes: [String]
        public let fingerprint: String
        public let sharingFlags: [ProfileSharingFlag]
        public let requiredFeatures: Set<AppFeature>

        public init(id: Identifier, name: String, moduleTypes: [String], fingerprint: String, sharingFlags: [ProfileSharingFlag], requiredFeatures: Set<AppFeature>) {
            self.id = id
            self.name = name
            self.moduleTypes = moduleTypes
            self.fingerprint = fingerprint
            self.sharingFlags = sharingFlags
            self.requiredFeatures = requiredFeatures
        }

        public func withNewId() -> Self {
            var copy = self
            copy.id = UUID().uuidString
            return copy
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.name.lowercased() < rhs.name.lowercased()
        }
    }

    public struct Profile: Identifiable, Hashable, Sendable, DTO {
        public private(set) var header: ProfileHeader

        public var id: Identifier {
            header.id
        }

        public init(header: ProfileHeader) {
            self.header = header
        }

        public mutating func renewId() {
            header = header.withNewId()
        }
    }
}
