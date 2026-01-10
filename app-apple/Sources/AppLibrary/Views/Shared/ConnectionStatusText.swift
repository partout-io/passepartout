// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout
import SwiftUI

public struct ConnectionStatusText: View {
    let tunnel: TunnelObservable

    let profileId: ABI.AppIdentifier?

    let withColors: Bool

    public init(tunnel: TunnelObservable, profileId: ABI.AppIdentifier?, withColors: Bool = true) {
        self.tunnel = tunnel
        self.profileId = profileId
        self.withColors = withColors
    }

    public var body: some View {
        if let profileId, tunnel.isActiveProfile(withId: profileId) {
            ConnectionStatusDynamicText(tunnel: tunnel, profileId: profileId, withColors: withColors)
        } else {
            ConnectionStatusStaticText(status: .disconnected, color: .secondary)
        }
    }
}

private struct ConnectionStatusStaticText: View {
    private let statusDescription: String

    private let color: Color

    init(status: ABI.AppProfile.Status, color: Color) {
        statusDescription = status.localizedDescription
        self.color = color
    }

    init(statusDescription: String, color: Color) {
        self.statusDescription = statusDescription
        self.color = color
    }

    var body: some View {
        Text(statusDescription)
            .foregroundStyle(color)
    }
}

private struct ConnectionStatusDynamicText: View {

    @Environment(Theme.self)
    private var theme

    let tunnel: TunnelObservable

    let profileId: ABI.AppIdentifier

    let withColors: Bool

    public var body: some View {
        ConnectionStatusStaticText(
            statusDescription: statusDescription,
            color: withColors ? tunnel.statusColor(ofProfileId: profileId, theme) : .primary
        )
    }
}

private extension ConnectionStatusDynamicText {
    var statusDescription: String {
        if let lastError = tunnel.lastError(for: profileId),
           case .partout(let partoutError) = lastError {
            return partoutError.code.localizedDescription(style: .tunnel)
        }
        let status = tunnel.status(for: profileId)
        switch status {
        case .connected:
            if let dataCount = tunnel.transfers[profileId] {
                let down = dataCount.received.descriptionAsDataUnit
                let up = dataCount.sent.descriptionAsDataUnit
                return "↓\(down) ↑\(up)"
            }
        case .disconnected:
            var desc = status.localizedDescription
            if let profile = tunnel.activeProfiles[profileId], profile.onDemand {
                desc += Strings.Views.Ui.ConnectionStatus.onDemandSuffix
            }
            return desc
        default:
            break
        }
        return status.localizedDescription
    }
}

// FIXME: #1594, Previews
#Preview("Status (Static)") {
    ConnectionStatusStaticText(status: .disconnecting, color: .cyan)
        .frame(width: 400, height: 100)
        .withMockEnvironment()
}

#Preview("Connected (Dynamic)") {
    ConnectionStatusDynamicText(tunnel: .forPreviews, profileId: Profile.forPreviews.id, withColors: true)
        .task {
            try? await TunnelManager.forPreviews.connect(with: .forPreviews)
        }
        .frame(width: 400, height: 100)
        .withMockEnvironment()
}

#Preview("On-Demand (Dynamic)") {
    var builder = Profile.Builder()
    let onDemand = OnDemandModule.Builder()
    builder.modules = [onDemand.build()]
    builder.activeModulesIds = [onDemand.id]
    let profile: Profile
    do {
        profile = try builder.build()
    } catch {
        fatalError()
    }
    return ConnectionStatusDynamicText(tunnel: .forPreviews, profileId: profile.id, withColors: true)
        .task {
            try? await TunnelManager.forPreviews.connect(with: profile)
        }
        .frame(width: 400, height: 100)
        .withMockEnvironment()
}
