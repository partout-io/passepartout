// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public enum Event: Sendable {
        case config(ConfigEvent)
        case iap(IAPEvent)
        case profile(ProfileEvent)
        case tunnel(TunnelEvent)
        case version(VersionEvent)
        case webReceiver(WebReceiverEvent)
    }

    public enum ConfigEvent: Sendable {
        case refresh(Set<ConfigFlag>, data: [ConfigFlag: JSON])
    }

    public enum IAPEvent: Sendable {
        case status(isEnabled: Bool)
        case eligibleFeatures(Set<AppFeature>)
        case loadReceipt(isLoading: Bool)
    }

    public enum ProfileEvent: Equatable, Sendable {
        case ready
        case localProfiles
        case refresh([Profile.ID: AppProfileHeader])
        case save(Profile, previous: Profile?)
        case startRemoteImport
        case stopRemoteImport
        case changeRemoteImporting(Bool)
    }

    public enum TunnelEvent: Sendable {
        case refresh([Profile.ID: AppProfileInfo])
        case dataCount
    }

    public enum VersionEvent: Sendable {
        case new(VersionRelease)
    }

    public enum WebReceiverEvent: Sendable {
        case start(website: WebsiteWithPasscode)
        case stop
        case newUpload(WebFileUpload)
        case uploadFailure(Error)
    }
}

// MARK: - Context and Callbacks

#if !PSP_CROSS
public typealias ABICallbackEvent = ABI.Event
#else
public typealias ABICallbackEvent = UnsafePointer<psp_event>
#endif

extension ABI {
    public struct EventContext: @unchecked Sendable {
        public let pointer: UnsafeRawPointer
        public init(pointer: UnsafeRawPointer) {
            self.pointer = pointer
        }
    }

    public typealias EventCallback = @Sendable (EventContext?, ABICallbackEvent) -> Void
}
