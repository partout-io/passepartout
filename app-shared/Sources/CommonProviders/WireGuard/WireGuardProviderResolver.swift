// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public struct WireGuardProviderResolver: ProviderModuleResolver {
    private let ctx: PartoutLoggerContext

    private let deviceId: String

    public var moduleType: ModuleType {
        .wireGuard
    }

    public init(_ ctx: PartoutLoggerContext, deviceId: String) {
        self.ctx = ctx
        self.deviceId = deviceId
    }

    public func resolved(from providerModule: ProviderModule) throws -> Module {
        try providerModule.compiled(
            ctx,
            withTemplate: WireGuardProviderTemplate.self,
            userInfo: WireGuardProviderTemplate.UserInfo(deviceId: deviceId)
        )
    }
}
