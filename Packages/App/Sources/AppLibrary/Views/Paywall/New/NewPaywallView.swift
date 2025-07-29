// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils
import SwiftUI

struct NewPaywallView: View, SizeClassProviding {

    @Environment(\.horizontalSizeClass)
    var hsClass

    @Environment(\.verticalSizeClass)
    var vsClass

    @Binding
    var isPresented: Bool

    @ObservedObject
    var iapManager: IAPManager

    let requiredFeatures: Set<AppFeature>

    @ObservedObject
    var model: PaywallCoordinator.Model

    @ObservedObject
    var errorHandler: ErrorHandler

    let onComplete: (String, InAppPurchaseResult) -> Void

    let onError: (Error) -> Void

    var body: some View {
#if os(tvOS)
        // use isBigDevice to also use fixed layout on macOS and iPad?
//        if isBigDevice {
            PaywallFixedView(
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
            PaywallScrollableView(
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
