// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol AppLogger {
    func log(_ category: ABI.AppLogCategory, _ level: ABI.AppLogLevel, _ message: String)
}
