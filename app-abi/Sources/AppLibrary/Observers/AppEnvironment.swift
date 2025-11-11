// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import CommonABI_C
import CommonABI
import CommonUtils
import SwiftUI

@MainActor
final class AppEnvironment {
    let configObserver: ConfigObserver
    let iapObserver: IAPObserver
    let preferencesObserver: PreferencesObserver
    let profileObserver: ProfileObserver
    let tunnelObserver: TunnelObserver

    init(
        configObserver: ConfigObserver,
        iapObserver: IAPObserver,
        preferencesObserver: PreferencesObserver,
        profileObserver: ProfileObserver,
        tunnelObserver: TunnelObserver
    ) {
        self.configObserver = configObserver
        self.iapObserver = iapObserver
        self.preferencesObserver = preferencesObserver
        self.profileObserver = profileObserver
        self.tunnelObserver = tunnelObserver
    }
}

extension View {
    func forPreviews() -> some View {
        withEnvironment(.forPreviews)
    }

    func withEnvironment(_ environment: AppEnvironment) -> some View {
        withEventsCallback(on: environment)
            .environment(environment.configObserver)
            .environment(environment.iapObserver)
            .environment(environment.preferencesObserver)
            .environment(environment.profileObserver)
            .environment(environment.tunnelObserver)
    }

    // This should rather be done in AppDelegate to ensure early initialization
    private func withEventsCallback(on environment: AppEnvironment) -> some View {
        onLoad {
            let opaqueEnvironment = Unmanaged.passRetained(environment).toOpaque()
            abi.initialize(eventContext: opaqueEnvironment, eventCallback: abiCallback)
        }
    }
}

private func abiCallback(opaqueEnvironment: UnsafeRawPointer?, event: ABI.Event) {
    guard let opaqueEnvironment else {
        fatalError("Missing AppEnvironment. Bad arguments to abi.initialize?")
    }
    let env = Unmanaged<AppEnvironment>.fromOpaque(opaqueEnvironment).takeUnretainedValue()
    Task { @MainActor in
        switch event {
        case .profiles:
            env.profileObserver.onUpdate(event)
        case .tunnel:
            env.tunnelObserver.onUpdate(event)
        }
    }
}
