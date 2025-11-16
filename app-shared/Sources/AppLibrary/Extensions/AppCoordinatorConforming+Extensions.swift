// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

extension AppCoordinatorConforming {
    public func onConnect(_ profile: ABI.AppProfile, force: Bool, verify: Bool = true) async {
        do {
            if verify {
                try iapObservable.verify(profile)
            }
            try await tunnel.connect(to: profile, force: force)
        } catch ABI.AppError.ineligibleProfile(let requiredFeatures) {
            onPurchaseRequired(for: profile, features: requiredFeatures) {
                Task {
                    await onConnect(profile, force: force, verify: false)
                }
            }
        } catch ABI.AppError.interactiveLogin {
            onInteractiveLogin(profile) { newProfile in
                Task {
                    await onConnect(newProfile, force: true, verify: verify)
                }
            }
        } catch let ppError as PartoutError {
            switch ppError.code {
            case .Providers.missingEntity:
                onProviderEntityRequired(profile, force: force)
            default:
                onError(ppError, profile: profile)
            }
        } catch {
            onError(error, profile: profile)
        }
    }

    public func onError(_ error: Error, profile: ABI.AppProfile) {
        onError(error, title: profile.native.name)
    }
}
