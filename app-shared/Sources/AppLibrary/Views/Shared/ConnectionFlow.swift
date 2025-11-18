// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

public struct ConnectionFlow {
    public let onConnect: @Sendable (Profile) async -> Void

    public let onProviderEntityRequired: @Sendable (Profile) -> Void

    public init(
        onConnect: @escaping @Sendable (Profile) async -> Void,
        onProviderEntityRequired: @escaping @Sendable (Profile) -> Void
    ) {
        self.onConnect = onConnect
        self.onProviderEntityRequired = onProviderEntityRequired
    }
}
