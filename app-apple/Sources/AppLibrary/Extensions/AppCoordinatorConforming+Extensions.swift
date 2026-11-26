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
            if profile.modules.contains(where: { $0.moduleType == .Provider || ($0 as? CustomModule)?.innerType == .Provider }) {
                onInfo(
                    title: Strings.Global.Nouns.providers,
                    message: Strings.Onboarding.Migrate395Providers.message
                )
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
                onInteractiveLogin(profile) { login in
                    Task {
                        do {
                            try await tunnel.connect(with: login)
                        } catch {
                            onError(error, profile: login.original)
                        }
                    }
                }
            default:
                onError(appError, profile: profile)
            }
        }
    }

    public func onError(_ error: Error, profile: Profile) {
        onError(error, title: profile.name)
    }
}
