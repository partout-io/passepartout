// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor
public protocol AppCoordinatorConforming {
    var iapObservable: IAPObservable { get }

    var tunnel: TunnelObservable { get }

    func onInteractiveLogin(_ profile: ABI.AppProfile, _ onComplete: @escaping InteractiveObservable.CompletionBlock)

    func onProviderEntityRequired(_ profile: ABI.AppProfile, force: Bool)

    func onPurchaseRequired(for profile: ABI.AppProfile, features: Set<ABI.AppFeature>, continuation: (() -> Void)?)

    func onError(_ error: Error, title: String)
}
