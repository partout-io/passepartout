// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class DummyWebReceiver: WebReceiver {
    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func start(passcode: String?, onReceive: @escaping (String, String) -> Void) throws -> URL {
//        assertionFailure("DummyWebReceiver: start()")
        return url
    }

    public func stop() {
//        assertionFailure("DummyWebReceiver: stop()")
    }
}
