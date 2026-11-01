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
    func givenWireGuardConfiguration_whenValidating_thenPassesBuiltModuleToValidator() {
        let sut = RegistryObservable(
            wireGuardKeyGenerator: FakeWireGuardKeyGenerator(),
            wireGuardValidateBlock: { module in
                let configuration = try #require(module.configuration)
                #expect(configuration.interface.privateKey.rawValue == privateKey)
                #expect(configuration.interface.addresses.map(\.rawValue) == ["10.0.0.1/24"])
                #expect(configuration.interface.mtu == 1280)
                let peer = try #require(configuration.peers.first)
                #expect(peer.publicKey.rawValue == publicKey)
                #expect(peer.preSharedKey?.rawValue == privateKey)
                #expect(peer.allowedIPs.map(\.rawValue) == ["0.0.0.0/0"])
                #expect(peer.endpoint?.address.rawValue == "example.com")
                #expect(peer.endpoint?.port == 51820)
                #expect(peer.keepAlive == 25)
                throw ValidationError.rejected
            }
        )
        var configuration = WireGuard.Configuration.Builder(privateKey: privateKey)
        configuration.interface.addresses = ["10.0.0.1/24"]
        configuration.interface.mtu = 1280
        var peer = WireGuard.RemoteInterface.Builder(publicKey: publicKey)
        peer.preSharedKey = privateKey
        peer.allowedIPs = ["0.0.0.0/0"]
        peer.endpoint = "example.com:51820"
        peer.keepAlive = 25
        configuration.peers = [peer]
        let builder = WireGuardModule.Builder(configurationBuilder: configuration)
        #expect(throws: ValidationError.rejected) {
            try sut.validate(builder)
        }
    }

    @Test(arguments: [
        "2003:123:abc:4f00::1:52999",
        "[2003:123:abc:4f00::1]:52999"
    ])
    func givenIPv6Endpoint_whenValidatingWireGuard_thenPassesIPv6AddressToValidator(endpoint: String) throws {
        let sut = RegistryObservable(
            wireGuardKeyGenerator: FakeWireGuardKeyGenerator(),
            wireGuardValidateBlock: { module in
                let endpoint = try #require(module.configuration?.peers.first?.endpoint)
                #expect(endpoint.address.rawValue == "2003:123:abc:4f00::1")
                #expect(endpoint.address.family == .v6)
                #expect(endpoint.port == 52999)
            }
        )
        var configuration = WireGuard.Configuration.Builder(privateKey: privateKey)
        var peer = WireGuard.RemoteInterface.Builder(publicKey: publicKey)
        peer.endpoint = endpoint
        configuration.peers = [peer]
        try sut.validate(WireGuardModule.Builder(configurationBuilder: configuration))
    }

    @Test
    func givenInvalidDNSServer_whenValidatingWireGuard_thenRejectsBeforeImporting() {
        let sut = RegistryObservable(
            wireGuardKeyGenerator: FakeWireGuardKeyGenerator(),
            wireGuardValidateBlock: { _ in Issue.record("Invalid DNS reached the importer") }
        )
        var configuration = WireGuard.Configuration.Builder(privateKey: privateKey)
        configuration.interface.dns = DNSModule.Builder(servers: ["example.com"])
        configuration.peers = [WireGuard.RemoteInterface.Builder(publicKey: publicKey)]
        #expect(throws: PartoutError.self) {
            try sut.validate(WireGuardModule.Builder(configurationBuilder: configuration))
        }
    }
}

private enum ValidationError: Error {
    case rejected
}

private let privateKey = "4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw="
private let publicKey = "muwialz9E36nXp9qgbGIxwMrH+5Ovr8d7cutH8JHdvE="
