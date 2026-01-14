// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonProviders
import MiniFoundation
import Partout
import Testing

struct ProviderModulesTests {
    private let mockId = ProviderID(rawValue: "hideme")

    private let resourcesURL = Bundle.module.url(forResource: "Resources", withExtension: nil)

    @Test
    func givenProviderModule_whenOpenVPN_thenResolves() throws {
        var sut = ProviderModule.Builder()
        sut.providerId = mockId
        sut.providerModuleType = .openVPN
        sut.entity = try openVPNEntity()

        let module = try sut.build()
        #expect(!module.isFinal)
        let resolvedModule = try OpenVPNProviderResolver(.global).resolved(from: module)
        #expect(resolvedModule.isFinal)
        let typedModule = try #require(resolvedModule as? OpenVPNModule)

        #expect(typedModule.configuration?.renegotiatesAfter == 900)
        #expect(typedModule.configuration?.remotes == [
            try .init("be-v4.hideservers.net", .init(.udp, 3000)),
            try .init("be-v4.hideservers.net", .init(.udp, 3010)),
            try .init("be-v4.hideservers.net", .init(.tcp, 3000)),
            try .init("be-v4.hideservers.net", .init(.tcp, 3020))
        ])
    }

    @Test
    func givenProviderModule_whenWireGuard_thenResolves() throws {
        let deviceId = "device_id"
        let addresses = ["8.9.10.11/32"]

        var sut = ProviderModule.Builder()
        sut.providerId = mockId
        sut.providerModuleType = .wireGuard

        let session = WireGuardProviderStorage.Session(privateKey: "", publicKey: "")
            .with(peer: WireGuardProviderStorage.Peer(id: deviceId, creationDate: Date(), addresses: addresses))
        var storage = WireGuardProviderStorage()
        storage.sessions = [deviceId: session]
        try sut.setOptions(storage, for: .wireGuard)

        sut.entity = try wireGuardEntity()

        let module = try sut.build()
        let resolvedModule = try WireGuardProviderResolver(.global, deviceId: deviceId)
            .resolved(from: module)
        #expect(resolvedModule is WireGuardModule)

        let wg = try #require(resolvedModule as? WireGuardModule)
        #expect(wg.configuration?.interface.addresses.map(\.rawValue) == addresses)
        #expect(wg.configuration?.interface.mtu == nil)
        #expect(wg.configuration?.peers.first?.publicKey.rawValue == "")
        #expect(wg.configuration?.peers.first?.endpoint?.address.rawValue == "1.2.3.4")
        #expect(wg.configuration?.peers.first?.endpoint?.port == 12345)
        #expect(wg.configuration?.peers.first?.allowedIPs.map(\.rawValue) == ["0.0.0.0/0", "::/0"])
        #expect(wg.configuration?.peers.first?.keepAlive == nil)
    }
}

private extension ProviderModulesTests {
    func openVPNEntity() throws -> ProviderEntity {
        let presetURL = try #require(resourcesURL?.miniAppending(path: "preset.openvpn.json"))
        let templateData = try Data(contentsOf: presetURL)

        return ProviderEntity(
            server: mockServer(withIPAddresses: false),
            preset: .init(
                providerId: mockId,
                presetId: "default",
                description: "Default",
                moduleType: .openVPN,
                templateData: templateData
            ),
            heuristic: nil
        )
    }

    func wireGuardEntity() throws -> ProviderEntity {
        let presetURL = try #require(resourcesURL?.miniAppending(path: "preset.wireguard.json"))
        let templateData = try Data(contentsOf: presetURL)

        return ProviderEntity(
            server: mockServer(withIPAddresses: true),
            preset: .init(
                providerId: mockId,
                presetId: "default",
                description: "Default",
                moduleType: .wireGuard,
                templateData: templateData
            ),
            heuristic: nil
        )
    }

    func mockServer(withIPAddresses: Bool) -> ProviderServer {
        ProviderServer(
            metadata: .init(
                providerId: mockId,
                categoryName: "default",
                countryCode: "BE",
                otherCountryCodes: nil,
                area: nil
            ),
            serverId: "be-v4",
            hostname: "be-v4.hideservers.net",
            ipAddresses: withIPAddresses ? [Data(hex: "01020304")] : nil, // 1.2.3.4
            supportedModuleTypes: [.openVPN, .wireGuard],
            supportedPresetIds: nil,
            userInfo: [
                "wgPublicKey": ""
            ]
        )
    }
}
