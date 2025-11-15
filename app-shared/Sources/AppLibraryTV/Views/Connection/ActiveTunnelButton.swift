// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ActiveTunnelButton: View {

    @EnvironmentObject
    private var theme: Theme

    let tunnel: TunnelObservable

    let profile: ABI.AppProfile?

    @FocusState.Binding
    var focusedField: ConnectionView.Field?

    let errorHandler: ErrorHandler

    let flow: ConnectionFlow?

    var body: some View {
        TunnelToggle(
            tunnel: tunnel,
            profile: profile,
            errorHandler: errorHandler,
            flow: flow
        ) { isOn, canInteract in
            Button(!isOn.wrappedValue ? Strings.Global.Actions.connect : Strings.Global.Actions.disconnect) {
                isOn.wrappedValue.toggle()
            }
            .frame(maxWidth: .infinity)
            .fontWeight(theme.relevantWeight)
            .forMainButton(
                withColor: toggleConnectionColor,
                focused: focusedField == .connect,
                disabled: !canInteract
            )
        }
    }
}

private extension ActiveTunnelButton {
    var toggleConnectionColor: Color {
        guard let activeProfile = tunnel.activeProfile else {
            return theme.enableColor
        }
        switch activeProfile.status {
        case .disconnected:
            return activeProfile.onDemand ? theme.disableColor : theme.enableColor
        default:
            return theme.disableColor
        }
    }
}
