// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class RegistryObservable {
    public let wireGuardKeyGenerator: WireGuardKeyGenerator
    private let wireGuardValidateBlock: @Sendable (WireGuardModule) throws -> Void

    public init(
        wireGuardKeyGenerator: WireGuardKeyGenerator,
        wireGuardValidateBlock: @Sendable @escaping (WireGuardModule) throws -> Void
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
        guard builder.configurationBuilder != nil else { return }
        try wireGuardValidateBlock(builder.build())
    }
}
