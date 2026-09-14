// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension WireGuardModule {
    public final class Implementation: ModuleImplementation, Sendable {
        public let moduleType = WireGuardModule.moduleType

        public let keyGenerator: WireGuardKeyGenerator

        public let validateBlock: @Sendable (String) throws -> Void

        public init(
            keyGenerator: WireGuardKeyGenerator,
            validateBlock: @escaping @Sendable (String) throws -> Void
        ) {
            self.keyGenerator = keyGenerator
            self.validateBlock = validateBlock
        }
    }
}

extension WireGuardModule.Implementation: ModuleBuilderValidator {
    public func validate(_ builder: any ModuleBuilder) throws {
        guard let wg = builder as? WireGuardModule.Builder else { return }
        guard let text = try wg.configurationBuilder?.toQuickConfig() else { return }
        try validateBlock(text)
    }
}

private extension WireGuard.Configuration.Builder {
    func toQuickConfig() throws -> String {
        var lines: [String] = []

        lines.append("[Interface]")
        lines.append("PrivateKey = \(interface.privateKey)")
        if !interface.addresses.isEmpty {
            lines.append("Address = \(interface.addresses.wgJoined)")
        }
        if let dns = interface.dns {
            try dns.servers.forEach {
                guard let addr = Address(rawValue: $0), addr.isIPAddress else {
                    throw PartoutError.invalidField(.DNS.nonIPServers)
                }
            }
            try dns.domains?.forEach {
                guard let addr = Address(rawValue: $0), !addr.isIPAddress else {
                    throw PartoutError.invalidField(.DNS.ipDomains)
                }
            }
            let dnsEntries = dns.servers + (dns.domains ?? [])
            if !dnsEntries.isEmpty {
                lines.append("DNS = \(dnsEntries.wgJoined)")
            }
        }
        if let mtu = interface.mtu {
            lines.append("MTU = \(mtu)")
        }

        peers.forEach {
            lines.append("[Peer]")
            lines.append("PublicKey = \($0.publicKey)")
            if let preSharedKey = $0.preSharedKey, !preSharedKey.isEmpty {
                lines.append("PresharedKey = \(preSharedKey)")
            }
            if !$0.allowedIPs.isEmpty {
                lines.append("AllowedIPs = \($0.allowedIPs.wgJoined)")
            }
            if let endpoint = $0.endpoint {
                lines.append("Endpoint = \(endpoint)")
            }
            if let persistentKeepAlive = $0.keepAlive {
                lines.append("PersistentKeepalive = \(persistentKeepAlive)")
            }
        }

        return lines.joined(separator: "\n")
    }
}

private extension Collection where Element == String {
    var wgJoined: String {
           joined(separator: ",")
    }
}
