// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public struct ProviderInfo: Hashable, Sendable {
        public let providerId: ProviderID
        public let countryCode: String?

        public init(providerId: ProviderID, countryCode: String?) {
            self.providerId = providerId
            self.countryCode = countryCode
        }
    }

    public struct AppProfileHeader: Identifiable, Hashable, Comparable, Sendable {
        public private(set) var id: Profile.ID
        public let name: String
        public let moduleTypes: [ModuleType]
        public let primaryModuleType: ModuleType?
        public let secondaryModuleTypes: [ModuleType]?
        public let providerInfo: ProviderInfo?
        public let fingerprint: String
        public let sharingFlags: [ProfileSharingFlag]
        public let requiredFeatures: Set<AppFeature>

        public init(
            id: Profile.ID,
            name: String,
            moduleTypes: [ModuleType],
            primaryModuleType: ModuleType?,
            secondaryModuleTypes: [ModuleType]?,
            providerInfo: ProviderInfo?,
            fingerprint: String,
            sharingFlags: [ProfileSharingFlag],
            requiredFeatures: Set<AppFeature>
        ) {
            self.id = id
            self.name = name
            self.moduleTypes = moduleTypes
            self.primaryModuleType = primaryModuleType
            self.secondaryModuleTypes = secondaryModuleTypes
            self.providerInfo = providerInfo
            self.fingerprint = fingerprint
            self.sharingFlags = sharingFlags
            self.requiredFeatures = requiredFeatures
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.name.lowercased() < rhs.name.lowercased()
        }
    }
}
