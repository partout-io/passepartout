// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

public struct ConnectionFlow {
    public let onConnect: (ABI.AppProfileHeader) async -> Void

    public init(
        onConnect: @escaping (ABI.AppProfileHeader) async -> Void
    ) {
        self.onConnect = onConnect
    }
}
