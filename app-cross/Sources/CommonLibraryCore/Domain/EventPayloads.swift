// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public protocol EventProtocol: Equatable, Encodable, Sendable {}
}

extension ABI.ConfigEvent {
    public struct Refresh: ABI.EventProtocol {
        public let flags: Set<ABI.ConfigFlag>
        public let data: [ABI.ConfigFlag: JSON]
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(QuicktypeConfigEventRefresh(
                data: data.reduce(into: [:]) {
                    $0[$1.key.rawValue] = $1.value
                },
                flags: Array(flags)
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
            try container.encode(QuicktypeIAPEventNewReceipt(
                isBeta: isBeta,
                originalPurchase: originalPurchase?.toProto,
                products: products.map(\.rawValue)
            ))
        }
    }
}

extension ABI.ProfileEvent {
    public struct Refresh: ABI.EventProtocol {
        public let headers: [Profile.ID: ABI.AppProfileHeader]
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(QuicktypeProfileEventRefresh(
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
            try container.encode(QuicktypeProfileEventSave())
        }
    }
}

extension ABI.TunnelEvent {
    public struct Refresh: ABI.EventProtocol {
        public let active: [Profile.ID: ABI.AppTunnelInfo]
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(QuicktypeTunnelEventRefresh(
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
            try container.encode(QuicktypeVersionEventNew(
                release: release.toProto
            ))
        }
    }
}
