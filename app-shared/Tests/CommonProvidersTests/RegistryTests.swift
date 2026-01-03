// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonProvidersCore
import Testing

struct RegistryTests {
    @Test
    func givenKnownHandlers_whenSerializeProfile_thenIsDeserialized() throws {
        let sut = Registry()

        var ovpnBuilder = OpenVPN.Configuration.Builder()
        ovpnBuilder.ca = OpenVPN.CryptoContainer(pem: "ca is required")
        ovpnBuilder.cipher = .aes128cbc
        ovpnBuilder.remotes = [
            try ExtendedEndpoint("host.name", EndpointProtocol(.tcp, 80))
        ]

        var wgBuilder = WireGuard.Configuration.Builder(privateKey: "")
        wgBuilder.peers = [WireGuard.RemoteInterface.Builder(publicKey: "")]

        var profileBuilder = Profile.Builder()
        profileBuilder.modules.append(try DNSModule.Builder().build())
        profileBuilder.modules.append(IPModule.Builder(ipv4: .init(subnet: try .init("1.2.3.4", 16))).build())
        profileBuilder.modules.append(OnDemandModule.Builder().build())
        profileBuilder.modules.append(try HTTPProxyModule.Builder(address: "1.1.1.1", port: 1080).build())
        profileBuilder.modules.append(try OpenVPNModule.Builder(configurationBuilder: ovpnBuilder).build())
        profileBuilder.modules.append(try WireGuardModule.Builder(configurationBuilder: wgBuilder).build())
        let profile = try profileBuilder.build()

        let encoded = try sut.json(fromProfile: profile)
        print(encoded)

        let decoded = try sut.profile(fromJSON: encoded)
        #expect(profile == decoded)
    }
}
