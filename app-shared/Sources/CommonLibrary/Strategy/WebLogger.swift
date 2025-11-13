// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol WebLogger {
    func debug(_ message: String)
    func info(_ message: String)
    func notice(_ message: String)
    func error(_ message: String)
}
