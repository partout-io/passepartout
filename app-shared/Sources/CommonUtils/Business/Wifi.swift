// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

@MainActor
public final class Wifi: ObservableObject {
    private let observer: WifiObserver

    public init(observer: WifiObserver) {
        self.observer = observer
    }

    public func currentSSID() async throws -> String {
        try await observer.currentSSID()
    }
}

public protocol WifiObserver {
    func currentSSID() async throws -> String
}
