// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_CROSS
import CommonProvidersCore
#endif
import Foundation
import Partout

public struct OpenVPNProviderResolver: ProviderModuleResolver {
    private let ctx: PartoutLoggerContext

    public var moduleType: ModuleType {
        .openVPN
    }

    public init(_ ctx: PartoutLoggerContext) {
        self.ctx = ctx
    }

    public func resolved(from providerModule: ProviderModule) throws -> Module {
        try providerModule.compiled(
            ctx,
            withTemplate: OpenVPNProviderTemplate.self,
            userInfo: nil
        )
    }
}
