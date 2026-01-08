// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct DiagnosticsProfileView: View {

    @ObservedObject
    private var tunnel: TunnelManager

    public let profile: Profile

    public init(tunnel: TunnelManager, profile: Profile) {
        self.tunnel = tunnel
        self.profile = profile
    }

    public var body: some View {
        Form {
            openVPNSection
        }
        .themeForm()
        .themeEmpty(if: isEmpty, message: Strings.Global.Nouns.noContent)
        .navigationTitle(profile.name)
    }
}

private extension DiagnosticsProfileView {
    var openVPNSection: some View {
        tunnel.value(
            forKey: TunnelEnvironmentKeys.OpenVPN.serverConfiguration,
            ofProfileId: profile.id
        )
        .map { cfg in
            Group {
                NavigationLink(Strings.Views.Diagnostics.Openvpn.Rows.serverConfiguration) {
                    OpenVPNView(serverConfiguration: cfg)
                        .navigationTitle(Strings.Views.Diagnostics.Openvpn.Rows.serverConfiguration)
                }
            }
            .themeSection(header: Strings.Unlocalized.openVPN)
        }
    }
}

private extension DiagnosticsProfileView {
    var isEmpty: Bool {
        [
            tunnel.value(forKey: TunnelEnvironmentKeys.OpenVPN.serverConfiguration, ofProfileId: profile.id)
        ]
            .filter {
                $0 != nil
            }
            .isEmpty
    }
}

#Preview {
    DiagnosticsProfileView(tunnel: .forPreviews, profile: .forPreviews)
        .withMockEnvironment()
}
