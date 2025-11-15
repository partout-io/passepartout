// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class PartoutLoggerStrategy: AppLogger, Sendable {
    public init() {}

    public func log(_ category: AppLogCategory, _ level: AppLogLevel, _ message: String) {
        pp_log_g(category.partoutCategory, level.partoutLevel, message)
    }
}

private extension AppLogCategory {
    var partoutCategory: LoggerCategory {
        switch self {
        case .core: .App.core
        case .iap: .App.iap
        case .profiles: .App.profiles
        case .web: .App.web
        }
    }
}

private extension AppLogLevel {
    var partoutLevel: DebugLog.Level {
        switch self {
        case .debug: .debug
        case .info: .info
        case .notice: .notice
        case .error: .error
        case .fault: .fault
        }
    }
}

// FIXME: #1594, Make internal
extension LoggerCategory {
    public enum App {
        public static let core = LoggerCategory(rawValue: AppLogCategory.core.id)

        public static let iap = LoggerCategory(rawValue: AppLogCategory.iap.id)

        public static let profiles = LoggerCategory(rawValue: AppLogCategory.profiles.id)

        public static let web = LoggerCategory(rawValue: AppLogCategory.web.id)
    }
}
