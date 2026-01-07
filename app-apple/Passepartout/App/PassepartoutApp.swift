// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS) || os(macOS)
import AppLibraryMain
import AppLibraryMainLegacy
#elseif os(tvOS)
import AppLibraryTV
import AppLibraryTVLegacy
#endif
import CommonLibrary
import Partout
import SwiftUI

@main
struct PassepartoutApp: App {

    @Environment(\.colorScheme)
    var colorScheme

#if os(iOS) || os(tvOS)

    @UIApplicationDelegateAdaptor
    private var appDelegate: AppDelegate

#elseif os(macOS)

    @NSApplicationDelegateAdaptor
    private var appDelegate: AppDelegate

#endif

    @Environment(\.scenePhase)
    var scenePhase

    @State
    var theme = Theme()
}

extension PassepartoutApp {
    var appName: String {
        context.appConfiguration.displayName
    }

    var context: AppContext {
        appDelegate.context
    }

#if os(macOS)
    var macSettings: MacSettings {
        appDelegate.macSettings
    }
#endif

    @ViewBuilder
    func contentView() -> some View {
#if os(tvOS)
        let flag: ABI.ConfigFlag = .observableTV
#else
        let flag: ABI.ConfigFlag = .observableMain
#endif
        if context.configObservable.isActive(flag) {
#if os(tvOS)
            AppCoordinator(
                profileObservable: context.profileObservable,
                tunnel: context.tunnelObservable,
                webReceiverObservable: context.webReceiverObservable
            )
#else
            // FIXME: #1594, Refactor like TV
            AppCoordinator(
                profileManager: context.profileManager,
                tunnel: context.tunnel,
                registry: context.registry,
                webReceiverManager: context.webReceiverManager
            )
#endif
        } else {
            LegacyAppCoordinator(
                profileManager: context.profileManager,
                tunnel: context.tunnel,
                registry: context.registry,
                webReceiverManager: context.webReceiverManager
            )
        }
    }
}
