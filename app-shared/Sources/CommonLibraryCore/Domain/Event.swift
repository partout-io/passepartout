// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: #1594, Delete import after deleting deprecated events
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
        case refresh(Set<ABI.ConfigFlag>)
    }

    public enum IAPEvent: Sendable {
        case status(isEnabled: Bool)
        case eligibleFeatures(Set<ABI.AppFeature>)
        case loadReceipt(isLoading: Bool)
    }

    public enum ProfileEvent: Equatable, Sendable {
        case ready
        case refresh([ABI.AppIdentifier: ABI.AppProfileHeader])
        case startRemoteImport
        case stopRemoteImport
        case changeRemoteImporting(Bool)

        @available(*, deprecated, message: "#1594")
        case localProfiles
        @available(*, deprecated, message: "#1594")
        case remoteProfiles
        @available(*, deprecated, message: "#1594")
        case filteredProfiles
        @available(*, deprecated, message: "#1594")
        case save(Profile, previous: Profile?)
        @available(*, deprecated, message: "#1594")
        case remove([Profile.ID])
    }

    public enum TunnelEvent: Sendable {
        case refresh([ABI.AppIdentifier: ABI.AppProfile.Info])
        case dataCount
    }

    public enum VersionEvent: Sendable {
        case new
    }

    public enum WebReceiverEvent: Sendable {
        case newUpload(ABI.WebFileUpload)
    }
}
