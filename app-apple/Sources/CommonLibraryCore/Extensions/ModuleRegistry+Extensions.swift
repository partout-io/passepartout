// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ModuleRegistry {
    public func newModule(ofType moduleType: ModuleType) -> any ModuleBuilder {
        guard var newBuilder = moduleType.builderType?.empty() else {
            fatalError("Unknown module type: \(self)")
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
            guard let impl = implementation(for: builder.moduleType) as? WireGuardModule.Implementation else {
                fatalError("Missing WireGuard implementation for module creation")
            }
            builder.configurationBuilder = WireGuard.Configuration.Builder(keyGenerator: impl.keyGenerator)
            newBuilder = builder
        default:
            break
        }
        return newBuilder
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
        case .Provider:
            return ProviderModule.Builder.self
        case .WireGuard:
            return WireGuardModule.Builder.self
        default:
            assertionFailure("ModuleType '\(rawValue)' has no ModuleBuilder associated")
            return nil
        }
    }
}
