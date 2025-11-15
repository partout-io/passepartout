// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class PartoutLoggerStrategy: AppLogger, Sendable {
    public init() {}

    public func log(_ category: ABI.AppLogCategory, _ level: ABI.AppLogLevel, _ message: String) {
        pp_log_g(category.partoutCategory, level.partoutLevel, message)
    }
}

private extension ABI.AppLogCategory {
    var partoutCategory: LoggerCategory {
        switch self {
        case .core: .App.core
        case .iap: .App.iap
        case .profiles: .App.profiles
        case .web: .App.web
        }
    }
}

private extension ABI.AppLogLevel {
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
        public static let core = LoggerCategory(.core)

        public static let iap = LoggerCategory(.iap)

        public static let profiles = LoggerCategory(.profiles)

        public static let web = LoggerCategory(.web)
    }

    private init(_ category: ABI.AppLogCategory) {
        self.init(rawValue: category.id)
    }
}


