// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public protocol WebReceiver {
    func start(passcode: String?, onReceive: @escaping (String, String) -> Void) throws -> URL

    func stop()
}
