// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibraryMain
import CommonLibrary
import Testing

@MainActor
struct WireGuardViewModelTests {
    @Test
    func givenIPv6Endpoint_whenLoadAndSave_thenPreservesSquareBrackets() throws {
        let publicKey = "peer"
        var peer = WireGuard.RemoteInterface.Builder(publicKey: publicKey)
        peer.endpoint = "2001:db8::1:51820"

        var configuration = WireGuard.Configuration.Builder(privateKey: "")
        configuration.peers = [peer]

        let draft = ModuleDraft(module: WireGuardModule.Builder(configurationBuilder: configuration))
        var sut = WireGuardView.ConfigurationView.ViewModel()

        sut.load(from: configuration)
        sut.save(to: draft, fallback: configuration)

        let savedEndpoint = try #require(draft.module.configurationBuilder?.peers.first?.endpoint)
        #expect(savedEndpoint == "[2001:db8::1]:51820")
    }
}
