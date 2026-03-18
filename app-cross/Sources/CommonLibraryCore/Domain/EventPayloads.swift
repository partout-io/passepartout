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
    public struct Status: ABI.EventProtocol {
        public let isEnabled: Bool
    }
    public struct LoadReceipt: ABI.EventProtocol {
        public let isLoading: Bool
    }
    public struct NewReceipt: ABI.EventProtocol {
        public let originalPurchase: ABI.OriginalPurchase?
        public let products: Set<ABI.AppProduct>
        public let isBeta: Bool
    }
    public struct EligibleFeatures: ABI.EventProtocol {
        public let features: Set<ABI.AppFeature>
        public let forComplete: Bool
        public let forFeedback: Bool
    }
}

extension ABI.ProfileEvent {
    public struct Ready: ABI.EventProtocol { public init() {} }
    public struct LocalProfiles: ABI.EventProtocol { public init() {} }
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
    public struct StartRemoteImport: ABI.EventProtocol { public init() {} }
    public struct StopRemoteImport: ABI.EventProtocol { public init() {} }
    public struct ChangeRemoteImporting: ABI.EventProtocol {
        public let isImporting: Bool
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

extension ABI.WebReceiverEvent {
    public struct Start: ABI.EventProtocol {
        public let website: ABI.WebsiteWithPasscode
    }
    public struct Stop: ABI.EventProtocol { public init() {} }
    public struct NewUpload: ABI.EventProtocol {
        public let file: ABI.WebFileUpload
    }
    public struct UploadFailure: ABI.EventProtocol {
        public let error: String
        public init(_ error: Error) {
            self.error = error.localizedDescription
        }
    }
}
