// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public struct OpenVPNProviderResolver: ProviderModuleResolver {
    public var moduleType: ModuleType {
        .openVPN
    }

    public init() {}

    public func resolved(from providerModule: ProviderModule) throws -> Module {
        try providerModule.compiled(
            withTemplate: OpenVPNProviderTemplate.self,
            userInfo: nil
        )
    }
}
