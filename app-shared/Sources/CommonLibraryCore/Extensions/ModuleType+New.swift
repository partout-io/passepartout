// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ModuleType {
    public func newModule(with registry: Registry) -> any ModuleBuilder {
        guard var newBuilder = registry.newModuleBuilder(withModuleType: self) else {
            fatalError("Unknown module type: \(self)")
        }
        switch self {
        case .openVPN:
            guard newBuilder is OpenVPNModule.Builder else {
                fatalError("Unexpected module builder type: \(type(of: newBuilder)) != \(self)")
            }

        case .wireGuard:
            guard var builder = newBuilder as? WireGuardModule.Builder else {
                fatalError("Unexpected module builder type: \(type(of: newBuilder)) != \(self)")
            }
            guard let impl = registry.implementation(for: builder) as? WireGuardModule.Implementation else {
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
