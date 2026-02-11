// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor
public protocol AppCoordinatorConforming {
    var iapObservable: IAPObservable { get }

    var tunnel: TunnelObservable { get }

    func onInteractiveLogin(_ profile: Profile, _ onComplete: @escaping InteractiveObservable.CompletionBlock)

    func onProviderEntityRequired(_ profile: Profile, force: Bool)

    func onPurchaseRequired(for profile: Profile, features: Set<ABI.AppFeature>, continuation: (() -> Void)?)

    func onError(_ error: Error, title: String)
}
