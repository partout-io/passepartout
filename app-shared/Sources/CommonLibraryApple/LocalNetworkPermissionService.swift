// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public final class LocalNetworkPermissionService {
    public init() {
    }

    public func request() {
        _ = ProcessInfo.processInfo.hostName
    }
}
