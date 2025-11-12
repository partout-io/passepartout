// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

import Foundation

extension DNSProtocol: LocalizableEntity {
    public var localizedDescription: String {
        switch self {
        case .cleartext:
            return Strings.Entities.DnsProtocol.cleartext
        case .https:
            return Strings.Entities.DnsProtocol.https
        case .tls:
            return Strings.Entities.DnsProtocol.tls
        @unknown default:
            return ""
        }
    }
}
