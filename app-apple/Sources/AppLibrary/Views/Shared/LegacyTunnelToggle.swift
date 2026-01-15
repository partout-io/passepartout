// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

@available(*, deprecated, message: "#1594")
public struct LegacyTunnelToggle<Label>: View where Label: View {

    @ObservedObject
    private var tunnel: TunnelManager

    private let profile: Profile?

    private let errorHandler: ErrorHandler

    private let flow: ConnectionFlow?

    private let label: (Binding<Bool>, Bool) -> Label

    public init(
        tunnel: TunnelManager,
        profile: Profile?,
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

public struct LegacyTunnelTextToggle: View {
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

extension LegacyTunnelToggle where Label == LegacyTunnelTextToggle {
    public init(_ title: String = "", tunnel: TunnelManager, profile: Profile?, errorHandler: ErrorHandler, flow: ConnectionFlow?) {
        self.init(tunnel: tunnel, profile: profile, errorHandler: errorHandler, flow: flow) { isOn, _ in
            LegacyTunnelTextToggle(title: title, isOn: isOn)
        }
    }
}

// MARK: -

private extension LegacyTunnelToggle {
    var isOnBinding: Binding<Bool> {
        Binding {
            isOn
        } set: {
            tryPerform(isOn: $0)
        }
    }
}

private extension LegacyTunnelToggle {
    var tunnelProfile: TunnelActiveProfile? {
        guard let profile else {
            return nil
        }
        return tunnel.activeProfiles[profile.id]
    }

    var isOn: Bool {
        guard let tunnelProfile else {
            return false
        }
        return tunnelProfile.status != .inactive || tunnelProfile.onDemand
    }

    var canInteract: Bool {
        profile != nil && tunnelProfile?.status != .deactivating
    }

    func tryPerform(isOn: Bool) {
        guard let profile else {
            return
        }
        Task {
            await perform(isOn: isOn, with: profile)
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
