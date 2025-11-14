// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout
import SwiftUI

@available(*, deprecated, message: "#1594")
public struct LegacyConnectionStatusText: View {

    @ObservedObject
    var tunnel: ExtendedTunnel

    let profileId: Profile.ID?

    let withColors: Bool

    public init(tunnel: ExtendedTunnel, profileId: Profile.ID?, withColors: Bool = true) {
        self.tunnel = tunnel
        self.profileId = profileId
        self.withColors = withColors
    }

    public var body: some View {
        if let profileId, tunnel.isActiveProfile(withId: profileId) {
            ConnectionStatusDynamicText(tunnel: tunnel, profileId: profileId, withColors: withColors)
        } else {
            ConnectionStatusStaticText(status: .inactive, color: .secondary)
        }
    }
}

private struct ConnectionStatusStaticText: View {
    private let statusDescription: String

    private let color: Color

    init(status: TunnelStatus, color: Color) {
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

    @EnvironmentObject
    private var theme: Theme

    @ObservedObject
    var tunnel: ExtendedTunnel

    let profileId: Profile.ID

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
        if let lastErrorCode = tunnel.lastErrorCode(ofProfileId: profileId) {
            return lastErrorCode.localizedDescription(style: .tunnel)
        }
        let status = tunnel.connectionStatus(ofProfileId: profileId)
        switch status {
        case .active:
            if let dataCount = tunnel.dataCount(ofProfileId: profileId) {
                let down = dataCount.received.descriptionAsDataUnit
                let up = dataCount.sent.descriptionAsDataUnit
                return "↓\(down) ↑\(up)"
            }

        case .inactive:
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

#Preview("Status (Static)") {
    ConnectionStatusStaticText(status: .deactivating, color: .cyan)
        .frame(width: 400, height: 100)
        .withMockEnvironment()
}

#Preview("Connected (Dynamic)") {
    ConnectionStatusDynamicText(tunnel: .forPreviews, profileId: Profile.forPreviews.id, withColors: true)
        .task {
            try? await ExtendedTunnel.forPreviews.connect(with: .forPreviews)
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
            try? await ExtendedTunnel.forPreviews.connect(with: profile)
        }
        .frame(width: 400, height: 100)
        .withMockEnvironment()
}
