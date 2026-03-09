// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public protocol EventProtocol: Sendable, Encodable {
        var type: String { get }
    }

    public struct EventHandler: @unchecked Sendable {
        public let context: UnsafeRawPointer?
        public let callback: EventCallback
        public init(context: UnsafeRawPointer?, callback: @escaping EventCallback) {
            self.context = context
            self.callback = callback
        }
    }

    public typealias EventCallback = @Sendable (UnsafeRawPointer?, ABI.EventProtocol) -> Void

    public struct EventWrapper: Encodable, Sendable {
        public enum CodingKeys: CodingKey {
            case type
            case subtype
            case payload
        }
        public let type: String
        public let payload: EventProtocol
        public init(_ event: EventProtocol) {
            self.type = event.type
            self.payload = event
        }
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            let subtype = "\(Swift.type(of: payload))"
            try container.encode(subtype, forKey: .subtype)
            try container.encode(payload, forKey: .payload)
        }
    }
}

extension ABI {
    public protocol ConfigEventProtocol: EventProtocol {}
    public protocol IAPEventProtocol: EventProtocol {}
    public protocol ProfileEventProtocol: EventProtocol {}
    public protocol TunnelEventProtocol: EventProtocol {}
    public protocol VersionEventProtocol: EventProtocol {}
    public protocol WebReceiverEventProtocol: EventProtocol {}
}

extension ABI.ConfigEventProtocol {
    public var type: String { "config" }
}

extension ABI.IAPEventProtocol {
    public var type: String { "iap" }
}

extension ABI.ProfileEventProtocol {
    public var type: String { "profile" }
}

extension ABI.TunnelEventProtocol {
    public var type: String { "tunnel" }
}

extension ABI.VersionEventProtocol {
    public var type: String { "version" }
}

extension ABI.WebReceiverEventProtocol {
    public var type: String { "webReceiver" }
}

extension ABI {
    public enum ConfigEvent {
        public struct Refresh: ConfigEventProtocol {
            public let flags: Set<ConfigFlag>
            public let data: [ConfigFlag: JSON]
        }
    }

    public enum IAPEvent {
        public struct Status: IAPEventProtocol {
            public let isEnabled: Bool
        }
        public struct LoadReceipt: IAPEventProtocol {
            public let isLoading: Bool
        }
        public struct NewReceipt: IAPEventProtocol {
            public let originalPurchase: OriginalPurchase?
            public let products: Set<AppProduct>
            public let isBeta: Bool
        }
        public struct EligibleFeatures: IAPEventProtocol {
            public let features: Set<AppFeature>
            public let forComplete: Bool
            public let forFeedback: Bool
        }
    }

    public enum ProfileEvent {
        public struct Ready: ProfileEventProtocol {}
        public struct LocalProfiles: ProfileEventProtocol {}
        public struct Refresh: ProfileEventProtocol {
            public let headers: [Profile.ID: AppProfileHeader]
        }
        public struct Save: ProfileEventProtocol {
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
        public struct StartRemoteImport: ProfileEventProtocol {}
        public struct StopRemoteImport: ProfileEventProtocol {}
        public struct ChangeRemoteImporting: ProfileEventProtocol {
            public let isImporting: Bool
        }
    }

    public enum TunnelEvent {
        public struct Refresh: TunnelEventProtocol {
            public let info: [Profile.ID: AppTunnelInfo]
        }
        public struct DataCount: TunnelEventProtocol {}
    }

    public enum VersionEvent {
        public struct New: VersionEventProtocol {
            public let release: VersionRelease
        }
    }

    public enum WebReceiverEvent {
        public struct Start: WebReceiverEventProtocol {
            public let website: WebsiteWithPasscode
        }
        public struct Stop: WebReceiverEventProtocol {}
        public struct NewUpload: WebReceiverEventProtocol {
            public let upload: WebFileUpload
        }
        public struct UploadFailure: WebReceiverEventProtocol {
            public let error: String
            public init(_ error: Error) {
                self.error = error.localizedDescription
            }
        }
    }
}
