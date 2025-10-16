// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public struct ProviderEntity: Hashable, Codable, Sendable {
    public struct Header: Hashable, Codable, Sendable {
        public let providerId: ProviderID

        public let id: String

        public let countryCode: String
    }

    public let server: ProviderServer

    public let preset: ProviderPreset

    public let heuristic: ProviderHeuristic?

    public init(server: ProviderServer, preset: ProviderPreset, heuristic: ProviderHeuristic?) {
        self.server = server
        self.preset = preset
        self.heuristic = heuristic
    }

    public var header: Header {
        Header(
            providerId: server.metadata.providerId,
            id: server.id,
            countryCode: server.metadata.countryCode
        )
    }
}
