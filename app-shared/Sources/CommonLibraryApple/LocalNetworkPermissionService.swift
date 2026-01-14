// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import MiniFoundation

public final class LocalNetworkPermissionService {
    public init() {
    }

    public func request() {
        _ = ProcessInfo.processInfo.hostName
    }
}
