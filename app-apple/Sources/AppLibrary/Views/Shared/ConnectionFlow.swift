// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

public struct ConnectionFlow {
    public let onConnect: (Profile) async -> Void

    public let onProviderEntityRequired: (Profile) -> Void

    public init(
        onConnect: @escaping (Profile) async -> Void,
        onProviderEntityRequired: @escaping (Profile) -> Void
    ) {
        self.onConnect = onConnect
        self.onProviderEntityRequired = onProviderEntityRequired
    }
}
