// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS) || os(macOS)
import AppLibraryMain
#elseif os(tvOS)
import AppLibraryTV
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

    func contentView() -> some View {
        AppCoordinator(
            profileObservable: context.profileObservable,
            tunnel: context.tunnelObservable,
            webReceiverObservable: context.webReceiverObservable
        )
    }
}
