// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public struct HTTPAddressPort {
    public enum Scheme: String {
        case http
        case https
    }

    public var scheme: Scheme

    public var address: String

    public var port: String

    public init(scheme: Scheme = .http, address: String = "", port: String = "") {
        self.scheme = scheme
        self.address = address
        self.port = port
    }

    public var url: URL? {
        guard let port = Int(port) else {
            return nil
        }
        guard !address.isEmpty else {
            return nil
        }
        return URL(string: "\(scheme)://\(address):\(port)")
    }
}
