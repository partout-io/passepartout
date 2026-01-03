// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout
import SwiftUI

public struct TunnelToggle<Label>: View where Label: View {
    private let tunnel: TunnelObservable

    private let profile: ABI.AppProfile?

    private let errorHandler: ErrorHandler

    private let flow: ConnectionFlow?

    private let label: (Binding<Bool>, Bool) -> Label

    public init(
        tunnel: TunnelObservable,
        profile: ABI.AppProfile?,
        errorHandler: ErrorHandler,
        flow: ConnectionFlow?,
        label: @escaping (Binding<Bool>, Bool) -> Label
    ) {
        self.tunnel = tunnel
        self.profile = profile
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
    public init(_ title: String = "", tunnel: TunnelObservable, profile: ABI.AppProfile?, errorHandler: ErrorHandler, flow: ConnectionFlow?) {
        self.init(tunnel: tunnel, profile: profile, errorHandler: errorHandler, flow: flow) { isOn, _ in
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
    var tunnelProfile: ABI.AppProfile.Info? {
        guard let profile else {
            return nil
        }
        return tunnel.activeProfiles[profile.id]
    }

    var isOn: Bool {
        guard let tunnelProfile else {
            return false
        }
        return tunnelProfile.status != .disconnected || tunnelProfile.onDemand
    }

    var canInteract: Bool {
        profile != nil && tunnelProfile?.status != .disconnecting
    }

    func tryPerform(isOn: Bool) {
        guard let profile else {
            return
        }
        Task {
            await perform(isOn: isOn, with: profile.native)
        }
    }

    func perform(isOn: Bool, with profile: Profile) async {
        do {
            if tunnelProfile != nil {
                if isOn {
                    await flow?.onConnect(profile)
                } else {
                    try await tunnel.disconnect(from: profile.id)
                }
            } else {
                await flow?.onConnect(profile)
            }
        } catch is CancellationError {
            //
        } catch {
            errorHandler.handle(
                error,
                title: profile.name,
                message: Strings.Errors.App.tunnel
            )
        }
    }
}
