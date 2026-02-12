// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct TunnelRestartButton<Label>: View where Label: View {
    let tunnel: TunnelObservable

    let header: ABI.AppProfileHeader?

    let errorHandler: ErrorHandler

    var flow: ConnectionFlow?

    let label: () -> Label

    var body: some View {
        Button {
            guard let header else { return }
            guard tunnel.status(for: header.id) == .connected else { return }
            Task {
                await flow?.onConnect(header)
            }
        } label: {
            label()
        }
        .disabled(isDisabled)
    }
}

private extension TunnelRestartButton {
    var isDisabled: Bool {
        guard let header else { return true }
        return tunnel.status(for: header.id) != .connected
    }
}
