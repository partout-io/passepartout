// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension AppCoordinatorConforming {
    public func onConnect(_ profile: Profile, force: Bool, verify: Bool = true) async {
        do {
            if verify {
                try iapObservable.verify(profile, extra: nil)
            }
            try await tunnel.connect(to: profile, force: force)
        } catch {
            let appError = ABI.AppError(error)
            switch appError {
            case .ineligibleProfile(let requiredFeatures):
                onPurchaseRequired(for: profile, features: requiredFeatures) {
                    Task {
                        await onConnect(profile, force: force, verify: false)
                    }
                }
            case .interactiveLogin:
                onInteractiveLogin(profile) { newProfile in
                    Task {
                        // Force to not re-present the interactive login
                        await onConnect(newProfile, force: true, verify: verify)
                    }
                }
            case .missingProviderEntity:
                onProviderEntityRequired(profile, force: force)
            default:
                onError(appError, profile: profile)
            }
        }
    }

    public func onError(_ error: Error, profile: Profile) {
        onError(error, title: profile.name)
    }
}
