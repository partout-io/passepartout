// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonProvidersCore
import Foundation
import Partout

extension DefaultAPIMapper {
    public convenience init(
        _ ctx: PartoutLoggerContext,
        baseURL: URL,
        timeout: TimeInterval
    ) {
        let api = DefaultProviderScriptingAPI(ctx, timeout: timeout)
        self.init(ctx, baseURL: baseURL, timeout: timeout, api: api)
    }

    public convenience init(
        _ ctx: PartoutLoggerContext,
        baseURL: URL,
        timeout: TimeInterval,
        api: DefaultProviderScriptingAPI
    ) {
        self.init(ctx, baseURL: baseURL, timeout: timeout, api: api) {
            $0.newScriptingEngine(ctx)
        }
    }
}
