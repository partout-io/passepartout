// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension UI {
    public enum ProfileSharingFlag: String, Codable, Sendable {
        case shared
        case tv
    }

    public struct ProfileHeader: Identifiable, DTO, Comparable, Sendable {
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
}
