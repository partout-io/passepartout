// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public struct ProviderRegion: Identifiable, Hashable, Codable, Sendable {
    public let id: String

    public let countryCode: String

    public let area: String?

    public init(countryCode: String, area: String?) {
        id = Self.id(countryCode: countryCode, area: area)
        self.countryCode = countryCode
        self.area = area
    }
}

extension ProviderRegion {
    public static func id(countryCode: String, area: String?) -> String {
        "\(countryCode).\(area ?? "*")"
    }
}

extension ProviderServer {
    public var region: ProviderRegion {
        ProviderRegion(countryCode: metadata.countryCode, area: metadata.area)
    }

    public var regionId: String {
        ProviderRegion.id(countryCode: metadata.countryCode, area: metadata.area)
    }
}
