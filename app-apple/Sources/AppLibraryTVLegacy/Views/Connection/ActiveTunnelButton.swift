// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ActiveTunnelButton: View {

    @Environment(Theme.self)
    private var theme

    @ObservedObject
    var tunnel: TunnelManager

    let profile: Profile?

    @FocusState.Binding
    var focusedField: ConnectionView.Field?

    let errorHandler: ErrorHandler

    let flow: ConnectionFlow?

    var body: some View {
        LegacyTunnelToggle(
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
        case .inactive:
            return activeProfile.onDemand ? theme.disableColor : theme.enableColor
        default:
            return theme.disableColor
        }
    }
}
