// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension UI {
    public typealias ProfileID = String

    public struct ProfileHeader: Identifiable, DTO, Comparable {
        public let id: ProfileID
        public let name: String
        // flags: icloud, tv

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.name < rhs.name
        }
    }
}
