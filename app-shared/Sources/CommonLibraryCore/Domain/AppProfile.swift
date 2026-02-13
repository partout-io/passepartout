// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public struct AppProfileHeader: Identifiable, Hashable, Comparable, Codable, Sendable {
        public struct ProviderInfo: Hashable, Codable, Sendable {
            public let providerId: ProviderID
            public let countryCode: String?

            public init(providerId: ProviderID, countryCode: String?) {
                self.providerId = providerId
                self.countryCode = countryCode
            }
        }

        public private(set) var id: Profile.ID
        public let name: String
        public let moduleTypes: [String]
        public let primaryModuleType: ModuleType?
        public let secondaryModuleTypes: [ModuleType]?
        public let providerInfo: ProviderInfo?
        public let fingerprint: String
        public let sharingFlags: [ProfileSharingFlag]
        public let requiredFeatures: Set<AppFeature>

        public init(
            id: Profile.ID,
            name: String,
            moduleTypes: [String],
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

    public enum AppTunnelStatus: Int, Codable, Sendable {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }

    public struct AppTunnelInfo: Identifiable, Hashable, Codable, Sendable {
        public let id: Profile.ID
        public let status: AppTunnelStatus
        public let onDemand: Bool

        public init(id: Profile.ID, status: AppTunnelStatus, onDemand: Bool) {
            self.id = id
            self.status = status
            self.onDemand = onDemand
        }
    }
}
