// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

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

extension AppFeature {
    public static let essentialFeatures: Set<AppFeature> = [
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

extension AppFeature: Identifiable {
    public var id: String {
        rawValue
    }
}

extension AppFeature: CustomDebugStringConvertible {
    public var debugDescription: String {
        rawValue
    }
}
