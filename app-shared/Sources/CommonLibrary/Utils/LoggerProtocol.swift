// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public protocol LoggerProtocol: Sendable {
    func debug(_ msg: String)

    func warning(_ msg: String)
}
