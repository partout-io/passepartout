// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol AppLogger {
    func log(_ category: AppLogCategory, _ level: AppLogLevel, _ message: String)
}
