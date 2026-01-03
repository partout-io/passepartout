// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

extension LegacyAppCoordinatorConforming {
    public func onConnect(_ profile: Profile, force: Bool, verify: Bool = true) async {
        do {
            if verify {
                try iapManager.verify(profile)
            }
            try await tunnel.connect(with: profile, force: force)
        } catch ABI.AppError.ineligibleProfile(let requiredFeatures) {
            onPurchaseRequired(for: profile, features: requiredFeatures) {
                Task {
                    await onConnect(profile, force: force, verify: false)
                }
            }
        } catch ABI.AppError.interactiveLogin {
            onInteractiveLogin(profile) { newProfile in
                Task {
                    await onConnect(newProfile.native, force: true, verify: verify)
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

    public func onError(_ error: Error, profile: Profile) {
        onError(error, title: profile.name)
    }
}
