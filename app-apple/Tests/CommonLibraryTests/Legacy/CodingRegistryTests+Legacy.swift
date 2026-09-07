// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
@testable import PartoutLegacyCore
import Testing

// Decode always probes V3, then V2, then V1, so these legacy decode checks
// stay unparameterized.
struct CodingRegistryLegacyTests {
    @Test
    func givenCoder_whenDecodeProfileEncodedWithLegacyV2_thenIsDecoded() throws {
        let registry = Registry(withKnown: true)
        let encoder = LegacyProfileEncoderV2(registry)
        let fixture = try newLegacyV2ProfileFixture(encoder)
        let encoded = try encoder.encode(fixture.profile.asCodableProfileV2)

        let sut = CodingRegistry(registry: registry)
        let decoded = try sut.profile(fromString: encoded)
        #expect(decoded == fixture.profile)
    }

    @Test
    func givenCoder_whenDecodeProfileEncodedWithLegacyV1_thenDecodesWithoutRegistryHandlers() throws {
        let sut = CodingRegistry(registry: Registry(allHandlers: []))

        for module in try newKnownModules() {
            var builder = Profile.Builder(modules: [module])
            builder.userInfo = .object(["source": .string("legacy")])
            let profile = try builder.build()
            let fixture = try newLegacyV1ProfileFixture(profile)
            let decoded = try sut.profile(fromString: fixture.encoded)

            #expect(decoded == fixture.profile)
            #expect(decoded.modules.first?.moduleType == module.moduleType)
            #expect(String(reflecting: type(of: decoded.modules[0])) == String(reflecting: type(of: module)))
        }
    }

    @Test
    func givenLegacyV2_whenDecodeProfileWithUnknownModule_thenFailsWithUnknownModuleHandler() throws {
        let registry = Registry(allHandlers: [])
        let encoder = LegacyProfileEncoderV2(registry)
        let fixture = try newLegacyV2ProfileFixture(encoder)

        let error = #expect(throws: PartoutError.self) {
            _ = try encoder.decode(fixture.encoded)
        }
        #expect(error?.code == .unknownModuleHandler)
    }
}

private extension CodingRegistryLegacyTests {
    func newLegacyV2ProfileFixture(_ encoder: LegacyProfileEncoderV2) throws -> LegacyProfileFixture {
        let profile = try newTestProfile()
        let encoded = try encoder.encode(profile.asCodableProfileV2)
        return LegacyProfileFixture(profile: profile, encoded: encoded)
    }

    func newLegacyV1ProfileFixture(_ profile: Profile) throws -> LegacyProfileFixture {
        let moduleEncoder = JSONEncoder(userInfo: [.legacySwiftEncoding: true])
        let modules = try profile.modules.map { module in
            guard let encodableModule = module as? any Encodable else {
                throw PartoutError(.encoding)
            }
            return LegacyModuleWrapperV1Fixture(
                id: module.moduleType,
                data: try moduleEncoder.encode(encodableModule)
            )
        }
        let payload = LegacyCodableProfileV1Fixture(
            version: profile.version,
            id: profile.id,
            name: profile.name,
            modules: modules,
            activeModulesIds: profile.activeModulesIds,
            behavior: profile.behavior,
            userInfo: try profile.userInfo.map {
                try JSONEncoder.shared().encode($0)
            }
        )
        let encoded = try JSONEncoder.shared().encode(payload).base64EncodedString()
        return LegacyProfileFixture(profile: profile, encoded: encoded)
    }

    func newTestProfile() throws -> Profile {
        let dnsModule = try DNSModule.Builder(
            id: UniqueID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            protocolType: .https,
            dohURL: "https://example.com/dns"
        ).build()
        let ipModule = IPModule.Builder(
            id: UniqueID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            mtu: 1280
        ).build()
        var builder = Profile.Builder(
            id: UniqueID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "legacy-profile",
            modules: [dnsModule, ipModule]
        )
        builder.userInfo = .object([
            "source": .string("legacy")
        ])
        return try builder.build()
    }

    func newKnownModules() throws -> [Module] {
        let dnsModule = try DNSModule.Builder(servers: ["1.1.1.1"]).build()
        let ipModule = IPModule.Builder(mtu: 1280).build()
        let httpProxyModule = try HTTPProxyModule.Builder(
            address: "1.1.1.1",
            port: 8080
        ).build()
        let onDemandModule = OnDemandModule.Builder().build()
        var openVPNConfiguration = OpenVPN.Configuration.Builder()
        openVPNConfiguration.ca = OpenVPN.CryptoContainer(pem: "ca is required")
        openVPNConfiguration.cipher = .aes128cbc
        openVPNConfiguration.remotes = [
            try ExtendedEndpoint("vpn.example.com", EndpointProtocol(.tcp, 443))
        ]
        let openVPNModule = try OpenVPNModule.Builder(
            configurationBuilder: openVPNConfiguration
        ).build()
        var wireGuardConfiguration = WireGuard.Configuration.Builder(privateKey: "")
        wireGuardConfiguration.peers = [WireGuard.RemoteInterface.Builder(publicKey: "")]
        let wireGuardModule = try WireGuardModule.Builder(
            configurationBuilder: wireGuardConfiguration
        ).build()
        return [
            dnsModule,
            httpProxyModule,
            ipModule,
            onDemandModule,
            openVPNModule,
            wireGuardModule
        ]
    }
}

private struct LegacyProfileFixture {
    let profile: Profile
    let encoded: String
}

private struct LegacyModuleWrapperV1Fixture: Encodable {
    let id: ModuleType

    let data: Data
}

private struct LegacyCodableProfileV1Fixture: Encodable {
    let version: Int?

    let id: UniqueID

    let name: String

    let modules: [LegacyModuleWrapperV1Fixture]

    let activeModulesIds: Set<UniqueID>

    let behavior: ProfileBehavior?

    let userInfo: Data?
}
