// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Foundation
import Partout
import Testing

struct LegacyProfileDecoderTests {
    @Test
    func givenKnownModules_whenDecodeV3Profile_thenPreservesModule() throws {
        let sut = LegacyProfileDecoder()

        var ovpnBuilder = OpenVPN.Configuration.Builder()
        ovpnBuilder.ca = OpenVPN.CryptoContainer(pem: "ca is required")
        ovpnBuilder.cipher = .aes128cbc
        ovpnBuilder.remotes = [
            try ExtendedEndpoint("host.name", EndpointProtocol(.tcp, 80))
        ]

        var wgBuilder = WireGuard.Configuration.Builder(privateKey: "")
        wgBuilder.peers = [WireGuard.RemoteInterface.Builder(publicKey: "")]

        var profileBuilder = Profile.Builder()
        profileBuilder.modules.append(try DNSModule.Builder(servers: ["1.1.1.1"]).build())
        profileBuilder.modules.append(IPModule.Builder(ipv4: .init(subnet: try .init("1.2.3.4", 16))).build())
        profileBuilder.modules.append(OnDemandModule.Builder().build())
        profileBuilder.modules.append(try HTTPProxyModule.Builder(address: "1.1.1.1", port: 1080).build())
        profileBuilder.modules.append(try OpenVPNModule.Builder(configurationBuilder: ovpnBuilder).build())
        profileBuilder.modules.append(try WireGuardModule.Builder(configurationBuilder: wgBuilder).build())
        for module in profileBuilder.modules {
            let profile = try Profile.Builder(modules: [module]).build()

            let encoded = try JSONEncoder.shared().encodeJSON(profile.asTaggedProfile)

            let decoded = try sut.profile(fromString: encoded)
            #expect(profile == decoded)
        }
    }

    @Test
    func givenCoder_whenDecodeV3ProfileWithLegacyOTPMethod_thenIsDecoded() throws {
        let sut = LegacyProfileDecoder()

        var ovpnBuilder = OpenVPN.Configuration.Builder()
        ovpnBuilder.ca = OpenVPN.CryptoContainer(pem: "ca is required")
        ovpnBuilder.cipher = .aes128cbc
        ovpnBuilder.remotes = [
            try ExtendedEndpoint("host.name", EndpointProtocol(.tcp, 80))
        ]
        let credentials = OpenVPN.Credentials.Builder(
            username: "user",
            password: "password",
            otpMethod: .append,
            otp: "123456"
        ).build()
        let module = try OpenVPNModule.Builder(
            configurationBuilder: ovpnBuilder,
            credentials: credentials
        ).build()
        let profile = try Profile.Builder(modules: [module]).build()

        let encoded = try JSONEncoder.shared().encodeJSON(profile.asTaggedProfile)
        let legacyEncoded = encoded.replacingOccurrences(
            of: "\"otpMethod\":\"append\"",
            with: "\"otpMethod\":{\"append\":{}}"
        )
        #expect(legacyEncoded != encoded)

        let decoded = try sut.profile(fromString: legacyEncoded)
        #expect(decoded == profile)
    }

    @Test
    func givenCoder_whenEncodeProfile_thenDecodesToEqual() throws {
        let sut = LegacyProfileDecoder()
        let dnsModule = try DNSModule.Builder(
            protocolType: .tls,
            servers: ["1.1.1.1", "4.4.4.4"],
            dotHostname: "hay.com"
        ).build()
        let ipModule = IPModule.Builder(mtu: 1234).build()
        let profile = try Profile.Builder(
            modules: [dnsModule, ipModule],
            userInfo: ["foo": "bar", "zen": 12]
        ).build()

        let encodedString = try JSONEncoder.shared().encodeJSON(profile.asTaggedProfile)
        let decodedProfile = try sut.profile(fromString: encodedString)
        #expect(decodedProfile.modules[0] as? DNSModule == dnsModule)
        #expect(decodedProfile.modules[1] as? IPModule == ipModule)
        #expect(decodedProfile == profile)
    }
}
