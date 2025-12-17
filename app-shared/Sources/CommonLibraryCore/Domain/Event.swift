// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: #1594, Delete import after deleting deprecated events
import Partout

extension ABI {
    public enum Event: Sendable {
        case iap(IAPEvent)
        case profile(ProfileEvent)
        case tunnel(TunnelEvent)
        case version(VersionEvent)
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
        @available(*, deprecated, message: "#1594")
        case changeRemoteImport
    }

    public enum TunnelEvent: Sendable {
        case refresh([ABI.AppIdentifier: ABI.AppProfile.Info])
        case dataCount
    }

    public enum VersionEvent: Sendable {
        case new
    }
}
