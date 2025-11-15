// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public enum AppLogCategory: String, Identifiable, Sendable {
    case core
    case iap
    case profiles
    case web

    public var id: String {
        "app.\(rawValue)"
    }
}

public enum AppLogLevel {
    case debug
    case info
    case notice
    case error
    case fault
}
