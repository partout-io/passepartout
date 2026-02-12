// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct DiagnosticsProfileView: View {
    private let tunnel: TunnelObservable

    private let header: ABI.AppProfileHeader

    public init(tunnel: TunnelObservable, header: ABI.AppProfileHeader) {
        self.tunnel = tunnel
        self.header = header
    }

    public var body: some View {
        Form {
            openVPNSection
        }
        .themeForm()
        .themeEmpty(if: isEmpty, message: Strings.Global.Nouns.noContent)
        .navigationTitle(header.name)
    }
}

private extension DiagnosticsProfileView {
    var openVPNSection: some View {
        openVPNServerConfiguration
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
        [openVPNServerConfiguration]
            .filter {
                $0 != nil
            }
            .isEmpty
    }

    var openVPNServerConfiguration: OpenVPN.Configuration? {
        tunnel.openVPNServerConfiguration(for: header.id)
    }
}

#Preview {
    DiagnosticsProfileView(tunnel: .forPreviews, header: .forPreviews)
        .withMockEnvironment()
}
