// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor
public protocol AppCoordinatorConforming {
    var iapManager: IAPManager { get }

    var tunnel: ExtendedTunnel { get }

    func onInteractiveLogin(_ profile: Profile, _ onComplete: @escaping InteractiveManager.CompletionBlock)

    func onProviderEntityRequired(_ profile: Profile, force: Bool)

    func onPurchaseRequired(for profile: Profile, features: Set<AppFeature>, onCancel: (() -> Void)?)

    func onError(_ error: Error, profile: Profile)
}
