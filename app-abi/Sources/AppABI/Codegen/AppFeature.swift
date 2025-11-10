// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension UI {
    public enum AppFeature: String, CaseIterable {
        case appleTV

        case dns

        case httpProxy

        case onDemand

        case otp

        case providers

        case routing

        case sharing
    }
}

extension UI.AppFeature {
    public static let essentialFeatures: Set<UI.AppFeature> = [
        .dns,
        .httpProxy,
        .onDemand,
        .otp,
        .providers,
        .routing,
        .sharing
    ]

    public var isEssential: Bool {
        Self.essentialFeatures.contains(self)
    }
}

extension UI.AppFeature: Identifiable {
    public var id: String {
        rawValue
    }
}

extension UI.AppFeature: CustomDebugStringConvertible {
    public var debugDescription: String {
        rawValue
    }
}
