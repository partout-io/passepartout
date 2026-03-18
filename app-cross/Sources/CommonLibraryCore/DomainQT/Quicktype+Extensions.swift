// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

protocol QuicktypeEncodable {
    associatedtype QuicktypeType
    var toProto: QuicktypeType { get }
}

// MARK: - ABI

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

extension ABI.AppProfileHeader: QuicktypeEncodable {
    var toProto: QuicktypeAppProfileHeader {
        QuicktypeAppProfileHeader(
            fingerprint: fingerprint,
            id: id.uuidString,
            moduleTypes: moduleTypes.compactMap(\.toProto),
            name: name,
            primaryModuleType: primaryModuleType?.toProto,
            providerInfo: providerInfo?.toProto,
            requiredFeatures: Array(requiredFeatures),
            secondaryModuleTypes: secondaryModuleTypes?.compactMap(\.toProto) ?? [],
            sharingFlags: sharingFlags
        )
    }
}

extension ABI.AppTunnelInfo: QuicktypeEncodable {
    var toProto: QuicktypeAppTunnelInfo {
        QuicktypeAppTunnelInfo(
            id: id.uuidString,
            onDemand: onDemand,
            status: status
        )
    }
}

extension ABI.ConfigFlag: CustomStringConvertible {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let known = Self(rawValue: rawValue) else {
            self = .unknown
            return
        }
        self = known
    }

    public var description: String {
        rawValue
    }
}

extension ABI.OriginalPurchase: QuicktypeEncodable {
    var toProto: QuicktypeOriginalPurchase {
        QuicktypeOriginalPurchase(
            buildNumber: buildNumber,
            purchaseDate: purchaseDate.formatted(.iso8601)
        )
    }
}

extension ABI.ProviderInfo: QuicktypeEncodable {
    var toProto: QuicktypeProviderInfo {
        QuicktypeProviderInfo(
            countryCode: countryCode,
            providerID: providerId.rawValue
        )
    }
}

extension ABI.SemanticVersion {
    public init?(_ string: String) {
        let tokens = string
            .components(separatedBy: ".")
            .compactMap(Int.init)
        guard tokens.count == 3 else {
            return nil
        }
        major = tokens[0]
        minor = tokens[1]
        patch = tokens[2]
    }
}

extension ABI.SemanticVersion: Comparable {
    private var value: Int {
        assert(major <= 0xff)
        assert(minor <= 0xff)
        assert(patch <= 0xff)
        return ((major & 0xff) << 16) + ((minor & 0xff) << 8) + patch
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }
}

extension ABI.SemanticVersion: CustomStringConvertible {
    public var description: String {
        "\(major).\(minor).\(patch)"
    }
}

extension ABI.VersionRelease: QuicktypeEncodable {
    var toProto: QuicktypeVersionRelease {
        QuicktypeVersionRelease(url: url.absoluteString, version: version)
    }
}

// MARK: - Partout

extension ModuleType: QuicktypeEncodable {
    var toProto: QuicktypeModuleType? {
        QuicktypeModuleType(rawValue: rawValue)
    }
}
