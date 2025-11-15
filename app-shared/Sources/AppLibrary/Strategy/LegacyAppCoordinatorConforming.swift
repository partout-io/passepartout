// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

@available(*, deprecated, message: "#1594")
@MainActor
public protocol LegacyAppCoordinatorConforming {
    var iapManager: IAPManager { get }

    var tunnel: ExtendedTunnel { get }

    func onInteractiveLogin(_ profile: Profile, _ onComplete: @escaping InteractiveManager.CompletionBlock)

    func onProviderEntityRequired(_ profile: Profile, force: Bool)

    func onPurchaseRequired(for profile: Profile, features: Set<ABI.AppFeature>, continuation: (() -> Void)?)

    func onError(_ error: Error, title: String)
}
