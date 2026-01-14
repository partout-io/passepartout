// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public func pspLog(
    _ category: ABI.AppLogCategory,
    _ level: ABI.AppLogLevel,
    _ message: String
) {
    pp_log_g(category.partoutCategory, level.partoutLevel, message)
}

public func pspLog(
    _ profileId: Profile.ID? = nil,
    _ category: ABI.AppLogCategory,
    _ level: ABI.AppLogLevel,
    _ message: String
) {
    pp_log_id(profileId, category.partoutCategory, level.partoutLevel, message)
}

public func pspLogFlush() {
    PartoutLogger.default.flushLog()
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

extension LoggerCategory {
    enum App {
        static let core = LoggerCategory(appCategory: .core)

        static let iap = LoggerCategory(appCategory: .iap)

        static let profiles = LoggerCategory(appCategory: .profiles)

        static let web = LoggerCategory(appCategory: .web)
    }

    init(appCategory: ABI.AppLogCategory) {
        self.init(rawValue: appCategory.id)
    }
}
