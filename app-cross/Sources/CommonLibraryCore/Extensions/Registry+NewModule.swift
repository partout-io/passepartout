// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension Registry {
    public func newModule(ofType moduleType: ModuleType) -> any ModuleBuilder {
        guard var newBuilder = newModuleBuilder(withModuleType: moduleType) else {
            fatalError("Unknown module type: \(self)")
        }
        switch moduleType {
        case .openVPN:
            guard newBuilder is OpenVPNModule.Builder else {
                fatalError("Unexpected module builder type: \(type(of: newBuilder)) != \(self)")
            }

        case .wireGuard:
            guard var builder = newBuilder as? WireGuardModule.Builder else {
                fatalError("Unexpected module builder type: \(type(of: newBuilder)) != \(self)")
            }
            guard let impl = implementation(for: builder) as? WireGuardModule.Implementation else {
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
