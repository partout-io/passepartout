//
//  EndpointAdvancedView+OpenVPN.swift
//  Passepartout
//
//  Created by Davide De Rosa on 3/8/22.
//  Copyright (c) 2022 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import SwiftUI
import TunnelKitOpenVPN
import PassepartoutLibrary

extension EndpointAdvancedView {
    struct OpenVPNView: View {
        @Binding var builder: OpenVPN.ConfigurationBuilder

        let isReadonly: Bool
        
        let isServerPushed: Bool
        
        private let fallbackConfiguration = OpenVPN.ConfigurationBuilder(withFallbacks: true).build()
        
        var body: some View {
            List {
                let cfg = builder.build()
                if isServerPushed {
                    ipv4Section
                    ipv6Section
                } else {
                    pullSection(configuration: cfg)
                }
                dnsSection(configuration: cfg)
                proxySection(configuration: cfg)
                if !isReadonly {
                    communicationEditableSection
                    compressionEditableSection
                } else {
                    communicationSection(configuration: cfg)
                    compressionSection(configuration: cfg)
                }
                if !isServerPushed {
                    tlsSection
                }
                otherSection(configuration: cfg)
            }
        }
    }
}

extension EndpointAdvancedView.OpenVPNView {
    private var ipv4Section: some View {
        builder.ipv4.map { cfg in
            Section {
                themeLongContentLinkDefault(
                    L10n.Global.Strings.address,
                    content: .constant(builder.ipv4.localizedAddress)
                )
                themeLongContentLinkDefault(
                    L10n.NetworkSettings.Gateway.title,
                    content: .constant(builder.ipv4.localizedDefaultGateway)
                )
            
                ForEach(cfg.routes, id: \.self) { route in
                    themeLongContentLinkDefault(
                        L10n.Endpoint.Advanced.Openvpn.Items.Route.caption,
                        content: .constant(route.localizedDescription)
                    )
                }
            } header: {
                Text(Unlocalized.Network.ipv4)
            }
        }
    }
    
    private var ipv6Section: some View {
        builder.ipv6.map { cfg in
            Section {
                themeLongContentLinkDefault(
                    L10n.Global.Strings.address,
                    content: .constant(builder.ipv6.localizedAddress)
                )
                themeLongContentLinkDefault(
                    L10n.NetworkSettings.Gateway.title,
                    content: .constant(builder.ipv6.localizedDefaultGateway)
                )

                ForEach(cfg.routes, id: \.self) { route in
                    themeLongContentLinkDefault(
                        L10n.Endpoint.Advanced.Openvpn.Items.Route.caption,
                        content: .constant(route.localizedDescription)
                    )
                }
            } header: {
                Text(Unlocalized.Network.ipv6)
            }
        }
    }

    private func pullSection(configuration: OpenVPN.Configuration) -> some View {
        configuration.pullMask.map { mask in
            Section {
                ForEach(mask, id: \.self) {
                    Text($0.localizedDescription)
                }
            } header: {
                Text(L10n.Global.Strings.pull)
            }
        }
    }

    private func communicationSection(configuration: OpenVPN.Configuration) -> some View {
        configuration.communicationSettings.map { settings in
            Section {
                settings.cipher.map {
                    Text(L10n.Endpoint.Advanced.Openvpn.Items.Cipher.caption)
                        .withTrailingText($0.localizedDescription)
                }
                settings.digest.map {
                    Text(L10n.Endpoint.Advanced.Openvpn.Items.Digest.caption)
                        .withTrailingText($0.localizedDescription)
                }
                settings.xor.map {
                    Text(Unlocalized.VPN.xor)
                        .withTrailingText($0.localizedDescriptionAsXOR)
                }
            } header: {
                Text(L10n.Endpoint.Advanced.Openvpn.Sections.Communication.header)
            }
        }
    }
    
    private var communicationEditableSection: some View {
        Section {
            themeTextPicker(
                L10n.Endpoint.Advanced.Openvpn.Items.Cipher.caption,
                selection: $builder.cipher ?? fallbackCipher,
                values: OpenVPN.Cipher.available,
                description: \.localizedDescription
            )
            themeTextPicker(
                L10n.Endpoint.Advanced.Openvpn.Items.Digest.caption,
                selection: $builder.digest ?? fallbackDigest,
                values: OpenVPN.Digest.available,
                description: \.localizedDescription
            )
            builder.xorMask.map {
                Text(Unlocalized.VPN.xor)
                    .withTrailingText($0.localizedDescriptionAsXOR)
            }
        } header: {
            Text(L10n.Endpoint.Advanced.Openvpn.Sections.Communication.header)
        }
    }
    
    private func compressionSection(configuration: OpenVPN.Configuration) -> some View {
        configuration.compressionSettings.map { settings in
            Section {
                settings.framing.map {
                    Text(L10n.Endpoint.Advanced.Openvpn.Items.CompressionFraming.caption)
                        .withTrailingText($0.localizedDescription)
                }
                settings.algorithm.map {
                    Text(L10n.Endpoint.Advanced.Openvpn.Items.CompressionAlgorithm.caption)
                        .withTrailingText($0.localizedDescription)
                }
            } header: {
                Text(L10n.Endpoint.Advanced.Openvpn.Sections.Compression.header)
            }
        }
    }
    
    private var compressionEditableSection: some View {
        Section {
            themeTextPicker(
                L10n.Endpoint.Advanced.Openvpn.Items.CompressionFraming.caption,
                selection: $builder.compressionFraming ?? fallbackCompressionFraming,
                values: OpenVPN.CompressionFraming.available,
                description: \.localizedDescription
            )
            themeTextPicker(
                L10n.Endpoint.Advanced.Openvpn.Items.CompressionAlgorithm.caption,
                selection: $builder.compressionAlgorithm ?? fallbackCompressionAlgorithm,
                values: OpenVPN.CompressionAlgorithm.available,
                description: \.localizedDescription
            ).disabled(builder.compressionFraming == .disabled)
        } header: {
            Text(L10n.Endpoint.Advanced.Openvpn.Sections.Compression.header)
        }
    }

    private func dnsSection(configuration: OpenVPN.Configuration) -> some View {
        configuration.dnsSettings.map { settings in
            Section {
                ForEach(settings.servers, id: \.self) {
                    Text(L10n.Global.Strings.address)
                        .withTrailingText($0, copyOnTap: true)
                }
                ForEach(settings.domains, id: \.self) {
                    Text(L10n.Global.Strings.domain)
                        .withTrailingText($0, copyOnTap: true)
                }
            } header: {
                Text(Unlocalized.Network.dns)
            }
        }
    }

    private func proxySection(configuration: OpenVPN.Configuration) -> some View {
        configuration.proxySettings.map { settings in
            Section {
                settings.proxy.map {
                    Text(L10n.Global.Strings.address)
                        .withTrailingText($0.rawValue, copyOnTap: true)
                }
                settings.pac.map {
                    Text(Unlocalized.Network.proxyAutoConfiguration)
                        .withTrailingText($0.absoluteString, copyOnTap: true)
                }
                ForEach(settings.bypass, id: \.self) {
                    Text(L10n.NetworkSettings.Items.ProxyBypass.caption)
                        .withTrailingText($0, copyOnTap: true)
                }
            } header: {
                Text(L10n.Global.Strings.proxy)
            }
        }
    }

    private var tlsSection: some View {
        Section {
            builder.ca.map { ca in
                themeLongContentLink(
                    Unlocalized.VPN.certificateAuthority,
                    content: .constant(ca.pem)
                )
            }
            builder.clientCertificate.map { cert in
                themeLongContentLink(
                    L10n.Endpoint.Advanced.Openvpn.Items.Client.caption,
                    content: .constant(cert.pem)
                )
            }
            builder.clientKey.map { key in
                themeLongContentLink(
                    L10n.Endpoint.Advanced.Openvpn.Items.ClientKey.caption,
                    content: .constant(key.pem)
                )
            }
            builder.tlsWrap.map { wrap in
                themeLongContentLink(
                    L10n.Endpoint.Advanced.Openvpn.Items.TlsWrapping.caption,
                    content: .constant(wrap.key.hexString),
                    withPreview: builder.tlsWrap.localizedDescription
                )
            }
            Text(L10n.Endpoint.Advanced.Openvpn.Items.Eku.caption)
                .withTrailingText(builder.checksEKU.localizedDescriptionAsEKU)
        } header: {
            Text(Unlocalized.Network.tls)
        }
    }

    private func otherSection(configuration: OpenVPN.Configuration) -> some View {
        configuration.otherSettings.map { settings in
            Section {
                settings.keepAlive.map {
                    Text(L10n.Global.Strings.keepalive)
                        .withTrailingText($0.localizedDescriptionAsKeepAlive)
                }
                settings.reneg.map {
                    Text(L10n.Endpoint.Advanced.Openvpn.Items.RenegotiationSeconds.caption)
                        .withTrailingText($0.localizedDescriptionAsRenegotiatesAfter)
                }
                settings.randomize.map {
                    Text(L10n.Endpoint.Advanced.Openvpn.Items.RandomEndpoint.caption)
                        .withTrailingText($0.localizedDescriptionAsRandomizeEndpoint)
                }
            } header: {
                Text(L10n.Endpoint.Advanced.Openvpn.Sections.Other.header)
            }
        }
    }
}

extension OpenVPN.Configuration {
    var communicationSettings: (cipher: OpenVPN.Cipher?, digest: OpenVPN.Digest?, xor: UInt8?)? {
        guard cipher != nil || digest != nil || xorMask != nil else {
            return nil
        }
        return (cipher, digest, xorMask)
    }

    var compressionSettings: (framing: OpenVPN.CompressionFraming?, algorithm: OpenVPN.CompressionAlgorithm?)? {
        guard compressionFraming != nil || compressionAlgorithm != nil else {
            return nil
        }
        return (compressionFraming, compressionAlgorithm)
    }
    
    var dnsSettings: (servers: [String], domains: [String])? {
        guard !(dnsServers?.isEmpty ?? true) || !(searchDomains?.isEmpty ?? true) else {
            return nil
        }
        return (dnsServers ?? [], searchDomains ?? [])
    }
    
    var proxySettings: (proxy: Proxy?, pac: URL?, bypass: [String])? {
        guard httpsProxy != nil || httpProxy != nil || proxyAutoConfigurationURL != nil || !(proxyBypassDomains?.isEmpty ?? true) else {
            return nil
        }
        return (httpsProxy ?? httpProxy, proxyAutoConfigurationURL, proxyBypassDomains ?? [])
    }
    
    var otherSettings: (keepAlive: TimeInterval?, reneg: TimeInterval?, randomize: Bool?)? {
        guard keepAliveInterval != nil || renegotiatesAfter != nil || randomizeEndpoint != nil else {
            return nil
        }
        return (keepAliveInterval, renegotiatesAfter, randomizeEndpoint)
    }
}

private extension EndpointAdvancedView.OpenVPNView {
    var fallbackCipher: OpenVPN.Cipher {
        fallbackConfiguration.cipher!
    }
    
    var fallbackDigest: OpenVPN.Digest {
        fallbackConfiguration.digest!
    }
    
    var fallbackCompressionFraming: OpenVPN.CompressionFraming {
        fallbackConfiguration.compressionFraming!
    }
    
    var fallbackCompressionAlgorithm: OpenVPN.CompressionAlgorithm {
        fallbackConfiguration.compressionAlgorithm!
    }
}
