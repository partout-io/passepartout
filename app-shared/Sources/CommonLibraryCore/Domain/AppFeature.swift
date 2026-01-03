// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public enum AppFeature: String, CaseIterable, Sendable {
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

extension ABI.AppFeature {
    public static let essentialFeatures: Set<Self> = [
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

extension ABI.AppFeature: Identifiable {
    public var id: String {
        rawValue
    }
}

extension ABI.AppFeature: CustomDebugStringConvertible {
    public var debugDescription: String {
        rawValue
    }
}
