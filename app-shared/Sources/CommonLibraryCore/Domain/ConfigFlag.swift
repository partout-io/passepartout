// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public enum ConfigFlag: String, CaseIterable, RawRepresentable, Codable, Sendable {
        // These must be permanent
        case allowsRelaxedVerification
        case appNotWorking
        // These are temporary (older activations come last)
        case neSocketUDP
        case neSocketTCP
        case tunnelABI
        case unknown
    }
}

extension ABI.ConfigFlag: CustomStringConvertible {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let known = Self(rawValue: rawValue) else {
            self = .unknown
            return
        }
        self = known
    }

    public var description: String {
        rawValue
    }
}
