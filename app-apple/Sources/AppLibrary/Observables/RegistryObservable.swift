// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class RegistryObservable {
    private let wireGuardKeyGenerator: WireGuardKeyGenerator

    public init(wireGuardKeyGenerator: WireGuardKeyGenerator) {
        self.wireGuardKeyGenerator = wireGuardKeyGenerator
    }

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
            builder.configurationBuilder = WireGuard.Configuration.Builder(
                keyGenerator: wireGuardKeyGenerator
            )
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
        case .WireGuard:
            return WireGuardModule.Builder.self
        default:
            assertionFailure("ModuleType '\(rawValue)' has no ModuleBuilder associated")
            return nil
        }
    }
}
