// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import AppABI_C
import CommonUtils
import SwiftUI

@MainActor
final class AppEnvironment {
    static let forPreviews = AppEnvironment(
        profileObserver: .forPreviews,
        tunnelObserver: .forPreviews
    )

    let profileObserver: ProfileObserver
    let tunnelObserver: TunnelObserver

    private init(
        profileObserver: ProfileObserver,
        tunnelObserver: TunnelObserver
    ) {
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

extension ProfileObserver {
    static let forPreviews = ProfileObserver()
}

extension TunnelObserver {
    static let forPreviews = TunnelObserver()
}

private func abiCallback(opaqueEnvironment: UnsafeMutableRawPointer?, event: psp_event) {
    guard let opaqueEnvironment else {
        fatalError("Missing AppEnvironment. Bad arguments to psp_initialize?")
    }
    let env = Unmanaged<AppEnvironment>.fromOpaque(opaqueEnvironment).takeUnretainedValue()
    Task { @MainActor in
        switch event.area {
        case PSPAreaProfile:
            env.profileObserver.onUpdate()
        case PSPAreaTunnel:
            env.tunnelObserver.onUpdate()
        default:
            break
        }
    }
}
