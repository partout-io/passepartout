// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension Endpoint {
    public var wgRepresentation: String {
        switch address {
        case .hostname(let hostname):
            return "\(hostname):\(port)"
        case .ip(let address, let family):
            switch family {
            case .v4:
                return "\(address):\(port)"
            case .v6:
                return "[\(address)]:\(port)"
            }
        @unknown default:
            fatalError()
        }
    }

    init?(withWgRepresentation string: String) {
        // Separation of host and port is based on 'parse_endpoint' function in
        // https://git.zx2c4.com/wireguard-tools/tree/src/config.c
        guard !string.isEmpty else { return nil }
        let startOfPort: String.Index
        let hostString: String
        if string.first! == "[" {
            // Look for IPv6-style endpoint, like [::1]:80
            let startOfHost = string.index(after: string.startIndex)
            guard let endOfHost = string.dropFirst().firstIndex(of: "]") else { return nil }
            let afterEndOfHost = string.index(after: endOfHost)
            if afterEndOfHost == string.endIndex { return nil }
            guard string[afterEndOfHost] == ":" else { return nil }
            startOfPort = string.index(after: afterEndOfHost)
            hostString = String(string[startOfHost ..< endOfHost])
        } else {
            // Look for an IPv4-style endpoint, like 127.0.0.1:80
            guard let endOfHost = string.firstIndex(of: ":") else { return nil }
            startOfPort = string.index(after: endOfHost)
            hostString = String(string[string.startIndex ..< endOfHost])
        }
        guard let endpointPort = UInt16(String(string[startOfPort ..< string.endIndex])) else { return nil }
        let invalidCharacterIndex = hostString.unicodeScalars.firstIndex { char in
            return !CharacterSet.urlHostAllowed.contains(char)
        }
        guard invalidCharacterIndex == nil else { return nil }
        try? self.init(hostString, endpointPort)
    }
}
