// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public final class PartoutAppLogger: AppLogger, Sendable {
    private let profileId: Profile.ID?

    public init(profileId: Profile.ID? = nil) {
        self.profileId = profileId
    }

    public func log(_ category: ABI.AppLogCategory, _ level: ABI.AppLogLevel, _ message: String) {
        pp_log_id(profileId, category.partoutCategory, level.partoutLevel, message)
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

// FIXME: #1594, Make internal, use AppLogger not pp_log
extension LoggerCategory {
    public enum App {
        public static let core = LoggerCategory(appCategory: .core)

        public static let iap = LoggerCategory(appCategory: .iap)

        public static let profiles = LoggerCategory(appCategory: .profiles)

        public static let web = LoggerCategory(appCategory: .web)
    }

    private init(appCategory: ABI.AppLogCategory) {
        self.init(rawValue: appCategory.id)
    }
}
