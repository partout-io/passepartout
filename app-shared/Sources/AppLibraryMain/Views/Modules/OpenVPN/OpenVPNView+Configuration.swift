// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension OpenVPNView.ConfigurationView where R == AnyHashable {
    init(isServerPushed: Bool, configuration: Binding<OpenVPN.Configuration.Builder>) {
        self.init(isServerPushed: isServerPushed, configuration: configuration, credentialsRoute: nil)
    }
}

extension OpenVPNView {
    struct ConfigurationView<R>: View where R: Hashable {
        let isServerPushed: Bool

        @Binding
        var configuration: OpenVPN.Configuration.Builder

        let credentialsRoute: R?

        var body: some View {
            accountSection
            if !isServerPushed {
                pullSection
            }
            redirectSection
            ipv4Section
            ipv6Section
            dnsSection
            proxySection
            communicationSection
            compressionSection
            if !isServerPushed {
                tlsSection
            }
            keepAliveSection
            otherSection
        }
    }
}

// MARK: - Constant

private extension OpenVPNView.ConfigurationView {
    var accountSection: some View {
        credentialsRoute.map { route in
            themeModuleSection(if: accountRows, header: Strings.Global.Nouns.account) {
                ProfileLink(
                    Strings.Modules.Openvpn.credentials,
                    route: route
                )
            }
        }
    }

    var pullSection: some View {
        configuration.pullMask
            .map { mask in
                themeModuleSection(if: pullRows, header: Strings.Modules.Openvpn.pull) {
                    ForEach(mask.map(\.localizedDescription).sorted(), id: \.self) {
                        ThemeRow($0)
                    }
                }
            }
    }

    var redirectSection: some View {
        configuration.routingPolicies
            .map { policies in
                themeModuleSection(if: redirectRows, header: Strings.Modules.Openvpn.redirectGateway) {
                    let sortedPolicies = policies.compactMap {
                        switch $0 {
                        case .IPv4: return Strings.Unlocalized.ipv4
                        case .IPv6: return Strings.Unlocalized.ipv6
                        default: return nil
                        }
                    }
                    .sorted()

                    ForEach(sortedPolicies, id: \.self) {
                        ThemeRow($0)
                    }
                }
            }
    }

    var ipv4Section: some View {
        themeModuleSection(
            if: ipRows(for: configuration.ipv4, routes: configuration.routes4),
            header: Strings.Unlocalized.ipv4
        ) {
            ipSection(for: configuration.ipv4, routes: configuration.routes4)
        }
    }

    var ipv6Section: some View {
        themeModuleSection(
            if: ipRows(for: configuration.ipv6, routes: configuration.routes6),
            header: Strings.Unlocalized.ipv6
        ) {
            ipSection(for: configuration.ipv6, routes: configuration.routes6)
        }
    }

    @ViewBuilder
    func ipSection(for ip: IPSettings?, routes: [Route]?) -> some View {
        ip?.localizedDescription(optionalStyle: .address)
            .map {
                ThemeCopiableText(Strings.Global.Nouns.address, value: $0)
            }

        ip?.localizedDescription(optionalStyle: .defaultGateway)
            .map {
                ThemeCopiableText(Strings.Global.Nouns.gateway, value: $0)
            }

        ((ip?.includedRoutes ?? []) + (routes ?? []))
            .nilIfEmpty
            .map {
                ThemeTextList(
                    Strings.Modules.Ip.Routes.included,
                    withEntries: true,
                    values: $0.map(\.localizedDescription),
                    copiable: true
                )
            }

        ip?.excludedRoutes
            .nilIfEmpty
            .map {
                ThemeTextList(
                    Strings.Modules.Ip.Routes.excluded,
                    withEntries: true,
                    values: $0.map(\.localizedDescription),
                    copiable: true
                )
            }
    }

    var dnsSection: some View {
        themeModuleSection(if: dnsRows, header: Strings.Unlocalized.dns) {
            configuration.dnsServers?
                .nilIfEmpty
                .map {
                    ThemeTextList(
                        Strings.Global.Nouns.servers,
                        withEntries: true,
                        values: $0,
                        copiable: true
                    )
                }

            configuration.dnsDomain.map {
                ThemeCopiableText(
                    Strings.Global.Nouns.domain,
                    value: $0
                )
            }

            configuration.searchDomains?
                .nilIfEmpty
                .map {
                    ThemeTextList(
                        Strings.Entities.Dns.searchDomains,
                        withEntries: true,
                        values: $0,
                        copiable: true
                    )
                }
        }
    }

    var proxySection: some View {
        themeModuleSection(if: proxyRows, header: Strings.Unlocalized.proxy) {
            configuration.httpProxy
                .map {
                    ThemeCopiableText(
                        Strings.Unlocalized.http,
                        value: $0.rawValue
                    )
                }

            configuration.httpsProxy
                .map {
                    ThemeCopiableText(
                        Strings.Unlocalized.https,
                        value: $0.rawValue
                    )
                }

            configuration.proxyAutoConfigurationURL
                .map {
                    ThemeCopiableText(
                        Strings.Unlocalized.pac,
                        value: $0.absoluteString
                    )
                }

            configuration.proxyBypassDomains?
                .nilIfEmpty
                .map {
                    ThemeTextList(
                        Strings.Entities.HttpProxy.bypassDomains,
                        withEntries: true,
                        values: $0,
                        copiable: true
                    )
                }
        }
    }

    var communicationSection: some View {
        themeModuleSection(if: communicationRows, header: Strings.Modules.Openvpn.communication) {
            configuration.cipher
                .map {
                    ThemeRow(Strings.Modules.Openvpn.cipher, value: $0.localizedDescription)
                }

            configuration.digest
                .map {
                    ThemeRow(Strings.Modules.Openvpn.digest, value: $0.localizedDescription)
                }

            configuration.xorMethod
                .map {
                    ThemeLongContentLink(
                        Strings.Unlocalized.xor,
                        text: .constant($0.localizedDescription(style: .long)),
                        preview: $0.localizedDescription(style: .short)
                    )
                }
        }
    }

    var compressionSection: some View {
        themeModuleSection(if: compressionRows, header: Strings.Modules.Openvpn.compression) {
            configuration.compressionFraming
                .map {
                    ThemeRow(
                        Strings.Modules.Openvpn.compressionFraming,
                        value: $0.localizedDescription
                    )
                }

            configuration.compressionAlgorithm
                .map {
                    ThemeRow(
                        Strings.Modules.Openvpn.compressionAlgorithm,
                        value: $0.localizedDescription
                    )
                }
        }
    }

    var tlsSection: some View {
        themeModuleSection(if: tlsRows, header: Strings.Unlocalized.tls) {
            configuration.ca
                .map {
                    ThemeLongContentLink(
                        Strings.Unlocalized.ca,
                        text: .constant($0.pem),
                        preview: ""
                    )
                }

            configuration.clientCertificate
                .map {
                    ThemeLongContentLink(
                        Strings.Global.Nouns.certificate,
                        text: .constant($0.pem),
                        preview: ""
                    )
                }

            configuration.clientKey
                .map {
                    ThemeLongContentLink(
                        Strings.Global.Nouns.key,
                        text: .constant($0.pem),
                        preview: ""
                    )
                }

            configuration.tlsWrap
                .map {
                    ThemeLongContentLink(
                        Strings.Modules.Openvpn.tlsWrap,
                        text: .constant($0.key.hexString),
                        preview: configuration.localizedDescription(style: .tlsWrap)
                    )
                }

            ThemeRow(
                Strings.Modules.Openvpn.eku,
                value: configuration.localizedDescription(style: .eku)
            )
        }
    }

    var keepAliveSection: some View {
        themeModuleSection(if: keepAliveRows, header: Strings.Global.Nouns.keepAlive) {
            configuration.localizedDescription(optionalStyle: .keepAlive)
                .map {
                    ThemeRow(Strings.Global.Nouns.interval, value: $0)
                }

            configuration.localizedDescription(optionalStyle: .keepAliveTimeout)
                .map {
                    ThemeRow(Strings.Global.Nouns.timeout, value: $0)
                }
        }
    }

    var otherSection: some View {
        themeModuleSection(if: otherRows, header: Strings.Global.Nouns.other) {
            configuration.localizedDescription(optionalStyle: .renegotiatesAfter)
                .map {
                    ThemeRow(Strings.Modules.Openvpn.renegotiation, value: $0)
                }

            configuration.localizedDescription(optionalStyle: .randomizeEndpoint)
                .map {
                    ThemeRow(Strings.Modules.Openvpn.randomizeEndpoint, value: $0)
                }

            configuration.localizedDescription(optionalStyle: .randomizeHostnames)
                .map {
                    ThemeRow(Strings.Modules.Openvpn.randomizeHostname, value: $0)
                }
        }
    }
}

private extension OpenVPNView.ConfigurationView {
    var accountRows: [Any?] {
        guard credentialsRoute != nil else {
            return []
        }
        guard configuration.authUserPass == true else {
            return []
        }
        return [
            configuration.authUserPass == true ? configuration.authUserPass : nil
        ]
    }

    var pullRows: [Any?] {
        [
            configuration.pullMask?.nilIfEmpty
        ]
    }

    var redirectRows: [Any?] {
        [
            configuration.routingPolicies?.nilIfEmpty
        ]
    }

    func ipRows(for ip: IPSettings?, routes: [Route]?) -> [Any?] {
        [
            ip?.subnets.first,
            ip?.localizedDescription(optionalStyle: .defaultGateway),
            ip?.includedRoutes.nilIfEmpty,
            routes?.nilIfEmpty,
            ip?.excludedRoutes.nilIfEmpty
        ]
    }

    var dnsRows: [Any?] {
        [
            configuration.dnsServers?.nilIfEmpty,
            configuration.dnsDomain,
            configuration.searchDomains?.nilIfEmpty
        ]
    }

    var proxyRows: [Any?] {
        [
            configuration.httpProxy,
            configuration.httpsProxy,
            configuration.proxyAutoConfigurationURL,
            configuration.proxyBypassDomains?.nilIfEmpty
        ]
    }

    var communicationRows: [Any?] {
        [
            configuration.cipher,
            configuration.digest,
            configuration.xorMethod
        ]
    }

    var compressionRows: [Any?] {
        [
            configuration.compressionFraming,
            configuration.compressionAlgorithm
        ]
    }

    var tlsRows: [Any?] {
        [
            configuration.ca,
            configuration.clientCertificate,
            configuration.clientKey,
            configuration.tlsWrap
        ]
    }

    var keepAliveRows: [Any?] {
        [
            configuration.keepAliveTimeout,
            configuration.keepAliveInterval
        ]
    }

    var otherRows: [Any?] {
        [
            configuration.renegotiatesAfter,
            configuration.randomizeEndpoint,
            configuration.randomizeHostnames
        ]
    }
}

// MARK: - Previews

#Preview {
    Form {
        OpenVPNView.ConfigurationView(
            isServerPushed: false,
            configuration: .constant(.forPreviews)
        )
    }
    .themeForm()
    .withMockEnvironment()
}
