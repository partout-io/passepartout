// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class RegistryObservable {
    public let wireGuardKeyGenerator: WireGuardKeyGenerator
    private let wireGuardValidateBlock: @Sendable (String) throws -> Void

    public init(
        wireGuardKeyGenerator: WireGuardKeyGenerator,
        wireGuardValidateBlock: @Sendable @escaping (String) throws -> Void
    ) {
        self.wireGuardKeyGenerator = wireGuardKeyGenerator
        self.wireGuardValidateBlock = wireGuardValidateBlock
    }

    public func newModule(ofType moduleType: ModuleType) -> (any ModuleBuilder)? {
        guard var newBuilder = moduleType.builderType?.empty() else {
            // Nil = legacy .Provider/.Custom, ignore until removed
//            fatalError("Unknown module type: \(moduleType)")
            return nil
        }
        switch moduleType {
        case .OpenVPN:
            guard newBuilder is OpenVPNModule.Builder else {
                fatalError("Unexpected module builder type: \(type(of: newBuilder)) != \(self)")
            }
        case .WireGuard:
            guard var builder = newBuilder as? WireGuardModule.Builder else {
                fatalError("Unexpected module builder type: \(type(of: newBuilder)) != \(self)")
            }
            builder.configurationBuilder = WireGuard.Configuration.Builder(
                keyGenerator: wireGuardKeyGenerator
            )
            newBuilder = builder
        default:
            break
        }
        return newBuilder
    }

    public func validate(_ builder: any ModuleBuilder) throws {
        switch builder {
        case let wgBuilder as WireGuardModule.Builder:
            try validateWireGuard(wgBuilder)
        default:
            break
        }
    }
}

private extension ModuleType {
    var builderType: (any ModuleBuilder.Type)? {
        switch self {
        case .DNS:
            return DNSModule.Builder.self
        case .HTTPProxy:
            return HTTPProxyModule.Builder.self
        case .IP:
            return IPModule.Builder.self
        case .OnDemand:
            return OnDemandModule.Builder.self
        case .OpenVPN:
            return OpenVPNModule.Builder.self
        case .WireGuard:
            return WireGuardModule.Builder.self
        case .Provider, .Custom:
            // Legacy
            return nil
        default:
            assertionFailure("ModuleType '\(rawValue)' has no ModuleBuilder associated")
            return nil
        }
    }
}

private extension RegistryObservable {
    func validateWireGuard(_ builder: WireGuardModule.Builder) throws {
        guard let text = try builder.configurationBuilder?.toQuickConfig() else { return }
        try wireGuardValidateBlock(text)
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
