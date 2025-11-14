// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

@MainActor
public protocol AppCoordinatorConforming {
    var iapManager: IAPManager { get }

    var tunnel: TunnelObservable { get }

    func onInteractiveLogin(_ profile: AppProfile, _ onComplete: @escaping InteractiveManager.CompletionBlock)

    func onProviderEntityRequired(_ profile: AppProfile, force: Bool)

    func onPurchaseRequired(for profile: AppProfile, features: Set<AppFeature>, continuation: (() -> Void)?)

    func onError(_ error: Error, title: String)
}
