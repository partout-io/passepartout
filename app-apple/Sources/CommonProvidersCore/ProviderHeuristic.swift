// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public enum ProviderHeuristic: Identifiable, Hashable, Codable, Sendable {
    case exact(ProviderServer)

    case sameCountry(String)

    case sameRegion(ProviderRegion)

    public var id: String {
        switch self {
        case .exact(let server):
            return "server.\(server.serverId)"
        case .sameCountry(let code):
            return "country.\(code)"
        case .sameRegion(let region):
            return "region.\(region.id)"
        }
    }
}

extension ProviderHeuristic {
    public func matches(_ server: ProviderServer) -> Bool {
        switch self {
        case .exact(let heuristicServer):
            return server.serverId == heuristicServer.serverId
        case .sameCountry(let code):
            return server.metadata.countryCode == code
        case .sameRegion(let region):
            return server.regionId == region.id
        }
    }
}
