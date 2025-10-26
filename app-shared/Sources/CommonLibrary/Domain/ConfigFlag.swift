// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public enum ConfigFlag: String, CaseIterable, RawRepresentable, Codable, Sendable {
    // These must be permanent
    case allowsRelaxedVerification
    case appNotWorking
    // These are temporary (older activations come last)
    case ovpnCrossConnection
    case tvSendTo
    case wgCrossParser
    case wgCrossConnection
    case neSocketUDP
    case neSocketTCP
    case tvWebImport            // 08/09
    case unknown
}

extension ConfigFlag: CustomStringConvertible {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let known = ConfigFlag(rawValue: rawValue) else {
            self = .unknown
            return
        }
        self = known
    }

    public var description: String {
        rawValue
    }
}
