// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct TunnelRestartButton<Label>: View where Label: View {

    @ObservedObject
    var tunnel: ExtendedTunnel

    let profile: Profile?

    let errorHandler: ErrorHandler

    var flow: ConnectionFlow?

    let label: () -> Label

    var body: some View {
        Button {
            guard let profile else {
                return
            }
            guard tunnel.status(ofProfileId: profile.id) == .active else {
                return
            }
            Task {
                await flow?.onConnect(profile)
            }
        } label: {
            label()
        }
        .disabled(isDisabled)
    }
}

private extension TunnelRestartButton {
    var isDisabled: Bool {
        guard let profile else {
            return true
        }
        return tunnel.status(ofProfileId: profile.id) != .active
    }
}
