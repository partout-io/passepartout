// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct TunnelToggle<Label>: View where Label: View {
    @Environment(ProfileObservable.self)
    private var profileObservable

    private let tunnel: TunnelObservable

    private let header: ABI.AppProfileHeader?

    private let errorHandler: ErrorHandler

    private let flow: ConnectionFlow?

    private let label: (Binding<Bool>, Bool) -> Label

    public init(
        tunnel: TunnelObservable,
        header: ABI.AppProfileHeader?,
        errorHandler: ErrorHandler,
        flow: ConnectionFlow?,
        label: @escaping (Binding<Bool>, Bool) -> Label
    ) {
        self.tunnel = tunnel
        self.header = header
        self.errorHandler = errorHandler
        self.flow = flow
        self.label = label
    }

    public var body: some View {
        label(isOnBinding, canInteract)
            .disabled(!canInteract)
    }
}

// MARK: Standard

public struct TunnelTextToggle: View {
    let title: String

    @Binding
    var isOn: Bool

    public var body: some View {
        Toggle(title, isOn: $isOn)
#if !os(tvOS)
            .toggleStyle(.switch)
#endif
    }
}

extension TunnelToggle where Label == TunnelTextToggle {
    public init(
        _ title: String = "",
        tunnel: TunnelObservable,
        header: ABI.AppProfileHeader?,
        errorHandler: ErrorHandler,
        flow: ConnectionFlow?
    ) {
        self.init(tunnel: tunnel, header: header, errorHandler: errorHandler, flow: flow) { isOn, _ in
            TunnelTextToggle(title: title, isOn: isOn)
        }
    }
}

// MARK: -

private extension TunnelToggle {
    var isOnBinding: Binding<Bool> {
        Binding {
            isOn
        } set: {
            tryPerform(isOn: $0)
        }
    }
}

private extension TunnelToggle {
    var tunnelProfile: ABI.AppProfileInfo? {
        guard let header else { return nil }
        return tunnel.activeProfiles[header.id]
    }

    var isOn: Bool {
        guard let tunnelProfile else { return false }
        return tunnelProfile.status != .disconnected || tunnelProfile.onDemand
    }

    var canInteract: Bool {
        header != nil && tunnelProfile?.status != .disconnecting
    }

    func tryPerform(isOn: Bool) {
        guard let header else { return }
        Task {
            await perform(isOn: isOn, with: header)
        }
    }

    func perform(isOn: Bool, with header: ABI.AppProfileHeader) async {
        do {
            if tunnelProfile != nil {
                if isOn {
                    await flow?.onConnect(header)
                } else {
                    try await tunnel.disconnect(from: header.id)
                }
            } else {
                await flow?.onConnect(header)
            }
        } catch is CancellationError {
            //
        } catch {
            errorHandler.handle(
                error,
                title: header.name,
                message: Strings.Errors.App.tunnel
            )
        }
    }
}
