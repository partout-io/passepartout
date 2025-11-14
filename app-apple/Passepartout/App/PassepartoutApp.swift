// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS) || os(macOS)
import AppLibraryMain
#elseif os(tvOS)
import AppLibraryTV
import AppLibraryTVLegacy
#endif

import CommonLibrary
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

    @StateObject
    var theme = Theme()
}

extension PassepartoutApp {
    var appName: String {
        BundleConfiguration.mainDisplayName
    }

    var context: AppContext {
        appDelegate.context
    }

#if os(macOS)
    var settings: MacSettingsModel {
        appDelegate.settings
    }
#endif

    func contentView() -> some View {
        LegacyAppCoordinator(
            profileManager: context.profileManager,
            tunnel: context.tunnel,
            registry: context.registry,
            webReceiverManager: context.webReceiverManager
        )
    }

    func newContentView() -> some View {
        AppCoordinator(
            profileObservable: ProfileObservable(
                logger: PartoutCategoryLogger(.App.profiles),
                profileManager: context.profileManager,
                registry: context.registry
            ),
            tunnel: context.tunnel,
            registry: context.registry,
            webReceiverManager: context.webReceiverManager
        )
    }
}
