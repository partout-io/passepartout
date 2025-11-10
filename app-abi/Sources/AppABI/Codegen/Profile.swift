// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension UI {
    public enum ProfileSharingFlag: String, Codable, Sendable {
        case shared
        case tv
    }

    public struct ProfileHeader: Identifiable, Comparable, Sendable, DTO {
        public let id: Identifier
        public let name: String
        public let moduleTypes: [String]
        public let fingerprint: String
        public let sharingFlags: [ProfileSharingFlag]
        // flags: icloud, tv

        init(id: Identifier, name: String, moduleTypes: [String] = [], fingerprint: String = "", sharingFlags: [ProfileSharingFlag] = []) {
            self.id = id
            self.name = name
            self.moduleTypes = moduleTypes
            self.fingerprint = fingerprint
            self.sharingFlags = sharingFlags
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.name.lowercased() < rhs.name.lowercased()
        }
    }

    public struct Profile {
        public private(set) var id: Identifier
        public var name: String
        public let fingerprint: String
        public let sharingFlags: [ProfileSharingFlag]

        public init(
            id: Identifier = UUID().uuidString,
            name: String,
            fingerprint: String = UUID().uuidString,
            sharingFlags: [ProfileSharingFlag] = []
        ) {
            self.id = id
            self.name = name
            self.fingerprint = fingerprint
            self.sharingFlags = sharingFlags
        }

        public mutating func renewId() {
            id = UUID().uuidString
        }

        public var header: ProfileHeader {
            ProfileHeader(
                id: id,
                name: name,
                moduleTypes: [], // FIXME: ###, after mapping modules
                fingerprint: fingerprint,
                sharingFlags: sharingFlags
            )
        }
    }
}
