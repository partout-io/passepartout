// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension WireGuard.Configuration.Builder {
    static var forPreviews: Self {
        let gen = FakeWireGuardKeyGenerator()

        var builder = WireGuard.Configuration.Builder(keyGenerator: gen)
        builder.interface.addresses = ["1.1.1.1", "2.2.2.2"]
        builder.interface.mtu = 1200
        var dns = DNSModule.Builder()
        dns.protocolType = .cleartext
        dns.servers = ["8.8.8.8", "4.4.4.4"]
        dns.domains = ["domain.com", "search1.com", "search2.net"]
        builder.interface.dns = dns

        do {
            builder.peers = try (0..<3).map { _ in
                let privateKey = gen.newPrivateKey()
                var peer = WireGuard.RemoteInterface.Builder(
                    publicKey: try gen.publicKey(for: privateKey)
                )
                peer.preSharedKey = gen.newPrivateKey()
                peer.allowedIPs = ["1.1.1.1/8", "2.2.2.2/12"]
                peer.endpoint = "8.8.8.8:12345"
                peer.keepAlive = 30
                return peer
            }
        } catch {
            fatalError()
        }
        return builder
    }
}
