// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class RegistryObservable {
    public init() {
    }

    @available(*, deprecated, message: "Legacy ModuleImplementation for WireGuard keygen, use ABI")
    public func newModule(ofType type: ModuleType) -> any ModuleBuilder {
        // FIXME: ###
//        registry.newModule(ofType: type)
        fatalError()
    }
}
