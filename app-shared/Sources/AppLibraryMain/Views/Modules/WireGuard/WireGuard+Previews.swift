// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

// swiftlint: disable force_try
extension WireGuard.Configuration.Builder {
    static var forPreviews: Self {
        let gen = MockGenerator()

        var builder = WireGuard.Configuration.Builder(keyGenerator: gen)
        builder.interface.addresses = ["1.1.1.1", "2.2.2.2"]
        builder.interface.mtu = 1200
        builder.interface.dns.protocolType = .cleartext
        builder.interface.dns.servers = ["8.8.8.8", "4.4.4.4"]
        builder.interface.dns.domainName = "domain.com"
        builder.interface.dns.searchDomains = ["search1.com", "search2.net"]

        builder.peers = (0..<3).map { _ in
            var peer = WireGuard.RemoteInterface.Builder(publicKey: try! gen.publicKey(for: gen.newPrivateKey()))
            peer.preSharedKey = gen.newPrivateKey()
            peer.allowedIPs = ["1.1.1.1/8", "2.2.2.2/12"]
            peer.endpoint = "8.8.8.8:12345"
            peer.keepAlive = 30
            return peer
        }
        return builder
    }
}
// swiftlint: enable force_try

private final class MockGenerator: WireGuardKeyGenerator {
    func newPrivateKey() -> String {
        "private-key-\(randomNumber)"
    }

    func privateKey(from string: String) throws -> String {
        "private-key-\(randomNumber)"
    }

    func publicKey(from string: String) throws -> String {
        "public-key-\(randomNumber)"
    }

    func publicKey(for privateKey: String) throws -> String {
        "public-key-\(randomNumber)"
    }

    private var randomNumber: Int {
        Int.random(in: 0..<1000)
    }
}
