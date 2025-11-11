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
        abi: ABIProtocol,
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

        let opaqueEnvironment = Unmanaged.passRetained(self).toOpaque()
        abi.registerEvents(context: opaqueEnvironment, callback: Self.abiCallback)
    }

    private static func abiCallback(opaqueEnvironment: UnsafeRawPointer?, event: ABI.Event) {
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
}

extension View {
    func forPreviews() -> some View {
        withEnvironment(.forPreviews)
    }

    func withEnvironment(_ environment: AppEnvironment) -> some View {
        self
            .environment(environment.configObserver)
            .environment(environment.iapObserver)
            .environment(environment.preferencesObserver)
            .environment(environment.profileObserver)
            .environment(environment.tunnelObserver)
    }
}
