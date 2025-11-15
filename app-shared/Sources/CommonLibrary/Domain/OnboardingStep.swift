// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// Order matters
extension ABI {
    public enum OnboardingStep: String, RawRepresentable, CaseIterable {
        case community
        case doneV3
        case migrateV3_2_3 // ProviderModule
        case doneV3_2_3
        case migrateV3_5_15 // JSON profiles
        case doneV3_5_15
        case dropLZOCompression
        case doneV3_5_18
    }
}

extension ABI.OnboardingStep {
    public static var first: Self {
        allCases.first!
    }

    public static var last: Self {
        allCases.last!
    }
}

extension ABI.OnboardingStep: Comparable {
    var order: Int {
        Self.allCases.firstIndex(of: self) ?? .max
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.order < rhs.order
    }
}
