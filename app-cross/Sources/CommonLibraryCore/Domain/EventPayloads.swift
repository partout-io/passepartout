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
    public struct Refresh: ABI.EventProtocol {
        public let headers: [Profile.ID: ABI.AppProfileHeader]
    }
    public struct Save: ABI.EventProtocol {
        private struct EncodableSave: Encodable {
            let profile: CodableProfile
            let previous: CodableProfile?
        }
        public let profile: Profile
        public let previous: Profile?
        public func encode(to encoder: any Encoder) throws {
            let cd = EncodableSave(
                profile: profile.asCodableProfile,
                previous: previous?.asCodableProfile
            )
            var container = encoder.singleValueContainer()
            try container.encode(cd)
        }
    }
    public struct ChangeRemoteImporting: ABI.EventProtocol {
        public let isImporting: Bool
    }
}

extension ABI.TunnelEvent {
    public struct Refresh: ABI.EventProtocol {
        public let active: [Profile.ID: ABI.AppTunnelInfo]
    }
}

extension ABI.VersionEvent {
    public struct New: ABI.EventProtocol {
        public let release: ABI.VersionRelease
    }
}

extension ABI.WebReceiverEvent {
    public struct Start: ABI.EventProtocol {
        public let website: ABI.WebsiteWithPasscode
    }
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
