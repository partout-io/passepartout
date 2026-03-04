// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public struct WireGuardProviderResolver: ProviderModuleResolver {
    private let deviceId: String

    public var moduleType: ModuleType {
        .wireGuard
    }

    public init(deviceId: String) {
        self.deviceId = deviceId
    }

    public func resolved(from providerModule: ProviderModule) throws -> Module {
        try providerModule.compiled(
            withTemplate: WireGuardProviderTemplate.self,
            userInfo: WireGuardProviderTemplate.UserInfo(deviceId: deviceId)
        )
    }
}
