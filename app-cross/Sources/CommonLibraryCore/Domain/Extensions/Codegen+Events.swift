// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public protocol EventProtocol: Equatable, Encodable, Sendable {}
}

// Events are typically codegenerated from OpenAPI. Here we keep
// the events where we want to:
//
// - Retain the Swift strong typing (for app-apple)
// - Manually encode to OpenAPI formats (for app-cross)
//
// Any other event that maps 1:1 to JSON is a typealias to OpenAPI.

extension ABI.ConfigEvent {
    public struct Refresh: ABI.EventProtocol {
        public let flags: Set<ABI.ConfigFlag>
        public let data: [ABI.ConfigFlag: JSON]
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(OpenAPIConfigEventRefresh(
                flags: Array(flags),
                data: data.reduce(into: [:]) {
                    $0[$1.key.rawValue] = $1.value
                }
            ))
        }
    }
}

extension ABI.IAPEvent {
    public struct NewReceipt: ABI.EventProtocol {
        public let originalPurchase: ABI.OriginalPurchase?
        public let products: Set<ABI.AppProduct>
        public let isBeta: Bool
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(OpenAPIIAPEventNewReceipt(
                originalPurchase: originalPurchase?.toProto,
                products: products.map(\.rawValue),
                isBeta: isBeta
            ))
        }
    }
}

extension ABI.ProfileEvent {
    public struct Refresh: ABI.EventProtocol {
        public let headers: [Profile.ID: ABI.AppProfileHeader]
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(OpenAPIProfileEventRefresh(
                headers: headers.reduce(into: [:]) {
                    $0[$1.key.uuidString] = $1.value.toProto
                }
            ))
        }
    }
    public struct Save: ABI.EventProtocol {
        public let profile: Profile
        public let previous: Profile?
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(OpenAPIProfileEventSave(
                profile: profile.asTaggedProfile,
                previous: previous?.asTaggedProfile
            ))
        }
    }
}

extension ABI.TunnelEvent {
    public struct Refresh: ABI.EventProtocol {
        public let active: [Profile.ID: ABI.AppTunnelInfo]
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(OpenAPITunnelEventRefresh(
                active: active.reduce(into: [:]) {
                    $0[$1.key.uuidString] = $1.value.toProto
                }
            ))
        }
    }
}

extension ABI.VersionEvent {
    public struct New: ABI.EventProtocol {
        public let release: ABI.VersionRelease
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(OpenAPIVersionEventNew(
                release: release.toProto
            ))
        }
    }
}
