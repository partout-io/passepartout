// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct DiagnosticsProfileView: View {
    private let tunnel: TunnelObservable

    private let header: ABI.AppProfileHeader

    @State
    private var openVPNServerConfiguration: OpenVPN.Configuration?

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
        .task {
            openVPNServerConfiguration = await tunnel.openVPNServerConfiguration(for: header.id)
        }
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
            .filter { $0 != nil }
            .isEmpty
    }
}

#Preview {
    DiagnosticsProfileView(tunnel: .forPreviews, header: .forPreviews)
        .withMockEnvironment()
}
