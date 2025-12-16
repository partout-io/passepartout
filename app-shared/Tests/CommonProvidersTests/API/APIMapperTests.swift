// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Testing

struct APIMapperTests: APITestSuite {
    init() {
        setUpLogging()
    }

    @Test
    func whenFetchIndex_thenReturnsProviders() async throws {
        let sut = try newAPIMapper()
        let index = try await sut.index()
        #expect(index.count == 11)
        #expect(index.map(\.description) == [
            "Hide.me",
            "IVPN",
            "Mullvad",
            "NordVPN",
            "Oeck",
            "PIA",
            "SurfShark",
            "TorGuard",
            "TunnelBear",
            "VyprVPN",
            "Windscribe"
        ])
    }
}
