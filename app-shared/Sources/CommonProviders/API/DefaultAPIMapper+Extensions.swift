// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

#if !PSP_CROSS
extension DefaultAPIMapper {
    public convenience init(
        baseURL: URL,
        timeout: TimeInterval
    ) {
        let api = DefaultProviderScriptingAPI(timeout: timeout)
        self.init(baseURL: baseURL, timeout: timeout, api: api)
    }

    public convenience init(
        baseURL: URL,
        timeout: TimeInterval,
        api: DefaultProviderScriptingAPI
    ) {
        self.init(baseURL: baseURL, timeout: timeout, api: api) {
            $0.newScriptingEngine()
        }
    }
}
#endif
