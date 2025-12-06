// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public protocol WebReceiver {
    func start(passcode: String?, onReceive: @escaping @Sendable (String, String) -> Void) throws -> URL
    func stop()
}

public struct WebReceiverError: Error {
    public let reason: Error?

    public init(_ reason: Error? = nil) {
        self.reason = reason
    }
}
