// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: #1594, Drop import (Profile.ID -> AppIdentifier, do not extend Partout.LoggerCategory)
import Partout

public final class PartoutAppLogger: AppLogger, Sendable {
    private let profileId: Profile.ID?

    public init(profileId: Profile.ID? = nil) {
        self.profileId = profileId
    }

    public func log(_ category: ABI.AppLogCategory, _ level: ABI.AppLogLevel, _ message: String) {
        pp_log_id(profileId, category.partoutCategory, level.partoutLevel, message)
    }

    public nonisolated func flushLogs() {
        PartoutLogger.default.flushLog()
    }
}

private extension ABI.AppLogCategory {
    var partoutCategory: LoggerCategory {
        switch self {
        case .core: .App.core
        case .iap: .App.iap
        case .profiles: .App.profiles
        case .providers: .App.providers
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

// FIXME: #1594, Use AppLogger, not pp_log
extension LoggerCategory {
    enum App {
        static let core = LoggerCategory(appCategory: .core)

        static let iap = LoggerCategory(appCategory: .iap)

        static let profiles = LoggerCategory(appCategory: .profiles)

        static let providers = LoggerCategory(appCategory: .providers)

        static let web = LoggerCategory(appCategory: .web)
    }

    private init(appCategory: ABI.AppLogCategory) {
        self.init(rawValue: appCategory.id)
    }
}
