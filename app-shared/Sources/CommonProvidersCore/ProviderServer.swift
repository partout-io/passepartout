// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public struct ProviderServer: Identifiable, Hashable, Codable, Sendable {
    public struct Metadata: Hashable, Codable, Sendable {
        public let providerId: ProviderID

        public let categoryName: String

        public let countryCode: String

        public let otherCountryCodes: [String]?

        public let area: String?

//        public let serverIndex: Int?
//
//        public let tags: [String]?
//
//        public let geo: (Double, Double)?

        public init(providerId: ProviderID, categoryName: String, countryCode: String, otherCountryCodes: [String]?, area: String?) {
            self.providerId = providerId
            self.categoryName = categoryName
            self.countryCode = countryCode
            self.otherCountryCodes = otherCountryCodes
            self.area = area
        }
    }

    public var id: String {
        [metadata.providerId.rawValue, serverId].joined(separator: ".")
    }

    public let metadata: Metadata

    public let serverId: String

    public let hostname: String?

    public let ipAddresses: Set<Data>?

    public let supportedModuleTypes: [ModuleType]?

    public let supportedPresetIds: [String]?

    public let userInfo: [String: String]?

    public init(metadata: Metadata, serverId: String, hostname: String?, ipAddresses: Set<Data>?, supportedModuleTypes: [ModuleType]?, supportedPresetIds: [String]?, userInfo: [String: String]? = nil) {
        self.metadata = metadata
        self.serverId = serverId
        self.hostname = hostname
        self.ipAddresses = ipAddresses
        self.supportedModuleTypes = supportedModuleTypes
        self.supportedPresetIds = supportedPresetIds
        self.userInfo = userInfo
    }
}

extension ProviderServer {
    public var allAddresses: [Address] {
        var list: [Address] = []
        if let hostname, let addr = Address(rawValue: hostname) {
            list.append(addr)
        }
        if let ipAddresses {
            list.append(contentsOf: ipAddresses.compactMap {
                Address(data: $0)
            })
        }
        return list
    }

    public var localizedCountry: String? {
        Locale.current.localizedString(forRegionCode: metadata.countryCode)
    }
}
