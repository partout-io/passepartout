// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

@MainActor @Observable
public final class Wifi {
    private let observer: WifiObserver

    public init(observer: WifiObserver) {
        self.observer = observer
    }

    public func currentSSID() async throws -> String {
        try await observer.currentSSID()
    }
}

public protocol WifiObserver: Sendable {
    func currentSSID() async throws -> String
}
