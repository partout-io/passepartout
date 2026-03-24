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

    public struct EventHandler: @unchecked Sendable {
        public let context: UnsafeMutableRawPointer?
        public let callback: EventCallback
        public init(context: UnsafeMutableRawPointer?, callback: @escaping EventCallback) {
            self.context = context
            self.callback = callback
        }
    }

    public typealias EventCallback = @Sendable (UnsafeMutableRawPointer?, ABI.Event) -> Void
}

extension ABI {
    public enum ConfigEvent: Sendable {
        case refresh(Refresh)
    }

    public enum IAPEvent: Sendable {
        case status(Status)
        case loadReceipt(LoadReceipt)
        case newReceipt(NewReceipt)
        case eligibleFeatures(EligibleFeatures)
    }

    public enum ProfileEvent: Equatable, Sendable {
        case ready(Ready = .init())
        case localProfiles(LocalProfiles = .init())
        case refresh(Refresh)
        case save(Save)
        case startRemoteImport(StartRemoteImport = .init())
        case stopRemoteImport(StopRemoteImport = .init())
        case changeRemoteImporting(ChangeRemoteImporting)
    }

    public enum TunnelEvent: Sendable {
        case dataCount(DataCount = .init())
        case refresh(Refresh)
    }

    public enum VersionEvent: Sendable {
        case new(New)
    }

    public enum WebReceiverEvent: Sendable {
        case start(Start)
        case stop(Stop = .init())
        case newUpload(NewUpload)
        case uploadFailure(UploadFailure)
    }
}
