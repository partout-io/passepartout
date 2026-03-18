// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

protocol QuicktypeEncodable {
    associatedtype QuicktypeType
    var toProto: QuicktypeType { get }
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
