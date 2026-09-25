// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
import CommonLibrary
import Testing

@MainActor
struct RegistryObservableTests {
    @Test(arguments: ModuleType.knownTypes)
    func givenKnownType_whenCreatingModule_thenReturnsMatchingBuilder(type: ModuleType) throws {
        let generator = FakeWireGuardKeyGenerator()
        let sut = RegistryObservable(wireGuardKeyGenerator: generator, wireGuardValidateBlock: { _ in })
        let builder = try #require(sut.newModule(ofType: type))
        #expect(builder.moduleType == type)
        if let wireGuard = builder as? WireGuardModule.Builder {
            #expect(wireGuard.configurationBuilder?.interface.privateKey == generator.newPrivateKey())
        }
    }

    @Test
    func givenWireGuardConfiguration_whenValidating_thenPassesQuickConfigToValidator() {
        let sut = RegistryObservable(
            wireGuardKeyGenerator: FakeWireGuardKeyGenerator(),
            wireGuardValidateBlock: { text in
                #expect(text == """
                [Interface]
                PrivateKey = private-key
                Address = 10.0.0.1/24
                MTU = 1280
                [Peer]
                PublicKey = public-key
                PresharedKey = preshared-key
                AllowedIPs = 0.0.0.0/0
                Endpoint = example.com:51820
                PersistentKeepalive = 25
                """)
                throw ValidationError.rejected
            }
        )
        var configuration = WireGuard.Configuration.Builder(privateKey: "private-key")
        configuration.interface.addresses = ["10.0.0.1/24"]
        configuration.interface.mtu = 1280
        var peer = WireGuard.RemoteInterface.Builder(publicKey: "public-key")
        peer.preSharedKey = "preshared-key"
        peer.allowedIPs = ["0.0.0.0/0"]
        peer.endpoint = "example.com:51820"
        peer.keepAlive = 25
        configuration.peers = [peer]
        let builder = WireGuardModule.Builder(configurationBuilder: configuration)
        #expect(throws: ValidationError.rejected) {
            try sut.validate(builder)
        }
    }

    @Test
    func givenInvalidDNSServer_whenValidatingWireGuard_thenRejectsBeforeImporting() {
        let sut = RegistryObservable(
            wireGuardKeyGenerator: FakeWireGuardKeyGenerator(),
            wireGuardValidateBlock: { _ in Issue.record("Invalid DNS reached the importer") }
        )
        var configuration = WireGuard.Configuration.Builder(privateKey: "private-key")
        configuration.interface.dns = DNSModule.Builder(servers: ["example.com"])
        #expect(throws: PartoutError.self) {
            try sut.validate(WireGuardModule.Builder(configurationBuilder: configuration))
        }
    }
}

private enum ValidationError: Error {
    case rejected
}
