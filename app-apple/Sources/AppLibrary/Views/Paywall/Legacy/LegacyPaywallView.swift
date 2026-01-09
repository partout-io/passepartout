// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

@available(*, deprecated, message: "#1594")
struct LegacyPaywallView: View, SizeClassProviding {

    @Environment(\.horizontalSizeClass)
    var hsClass

    @Environment(\.verticalSizeClass)
    var vsClass

    @Binding
    var isPresented: Bool

    @ObservedObject
    var iapManager: IAPManager

    let requiredFeatures: Set<ABI.AppFeature>

    let model: PaywallCoordinator.Model

    let errorHandler: ErrorHandler

    let onComplete: (String, ABI.StoreResult) -> Void

    let onError: (Error) -> Void

    var body: some View {
#if os(tvOS)
        // TODO: #1511, use isBigDevice to also use fixed layout on macOS and iPad?
//        if isBigDevice {
            LegacyPaywallFixedView(
                isPresented: $isPresented,
                iapManager: iapManager,
                requiredFeatures: requiredFeatures,
                model: model,
                errorHandler: errorHandler,
                onComplete: onComplete,
                onError: onError
            )
//        } else {
#else
            LegacyPaywallScrollableView(
                isPresented: $isPresented,
                iapManager: iapManager,
                requiredFeatures: requiredFeatures,
                model: model,
                errorHandler: errorHandler,
                onComplete: onComplete,
                onError: onError
            )
//        }
#endif
    }
}
