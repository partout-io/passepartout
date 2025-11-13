// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// Order matters
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

extension OnboardingStep {
    public static var first: Self {
        allCases.first!
    }

    public static var last: Self {
        allCases.last!
    }
}

extension OnboardingStep: Comparable {
    var order: Int {
        OnboardingStep.allCases.firstIndex(of: self) ?? .max
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.order < rhs.order
    }
}
