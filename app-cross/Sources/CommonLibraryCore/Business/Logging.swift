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

public func pspLogCurrent(_ parameters: ABI.AppConstants.Log) -> [String] {
    PartoutLogger.default.currentLog(
        sinceLast: parameters.sinceLast,
        maxLevel: parameters.options.maxDebugLogLevel
    )
}

public func pspLogFlush() {
    PartoutLogger.default.flushLog()
}

public func pspLogEntriesAvailable(at url: URL) -> [ABI.LogEntry] {
    LocalLogger.FileStrategy()
        .availableLogs(at: url)
        .sorted {
            $0.key > $1.key
        }
        .map {
            ABI.LogEntry(date: $0, url: $1)
        }
}

public func pspLogEntriesPurge(at url: URL) {
    LocalLogger.FileStrategy()
        .purgeLogs(at: url)
}

// MARK: - Registration

public enum LoggingTarget {
    case app
    case tunnelGlobal
    case tunnelProfile(Profile.ID)
}

nonisolated(unsafe)
private var isDefaultLoggerRegistered = false

@discardableResult
public func pspLogRegister(
    for target: LoggingTarget,
    with appConfiguration: ABI.AppConfiguration,
    preferences: ABI.AppPreferenceValues,
    mapper: @escaping @Sendable (DebugLog.Line) -> String
) -> PartoutLoggerContext {
    switch target {
    case .app:
        if !isDefaultLoggerRegistered {
            isDefaultLoggerRegistered = true
            let logger = PartoutLogger.logger(
                to: appConfiguration.bundle.urlForAppLog,
                preferences: preferences,
                parameters: appConfiguration.constants.log,
                mapper: mapper
            )
            PartoutLogger.register(logger)
            logger.logPreamble(
                versionString: appConfiguration.bundle.versionString,
                parameters: appConfiguration.constants.log
            )
        }
        return .global
    case .tunnelGlobal:
        let logger = PartoutLogger.tunnelLogger(
            to: appConfiguration.bundle.urlForTunnelLog,
            preferences: preferences,
            parameters: appConfiguration.constants.log,
            mapper: mapper
        )
        PartoutLogger.register(logger)
        logger.logPreamble(
            versionString: appConfiguration.bundle.versionString,
            parameters: appConfiguration.constants.log
        )
        return .global
    case .tunnelProfile(let profileId):
        if !isDefaultLoggerRegistered {
            isDefaultLoggerRegistered = true
            let logger = PartoutLogger.tunnelLogger(
                to: appConfiguration.bundle.urlForTunnelLog,
                preferences: preferences,
                parameters: appConfiguration.constants.log,
                mapper: mapper
            )
            PartoutLogger.register(logger)
        }
        return PartoutLoggerContext(profileId)
    }
}

// MARK: - Helpers

private extension PartoutLogger {
    static func logger(
        to url: URL,
        preferences: ABI.AppPreferenceValues,
        parameters: ABI.AppConstants.Log,
        mapper: @escaping @Sendable (DebugLog.Line) -> String
    ) -> PartoutLogger {
        var builder = PartoutLogger.Builder()
        builder.configureLogging(
            to: url,
            preferences: preferences,
            parameters: parameters,
            mapper: mapper
        )
        return builder.build()
    }

    static func tunnelLogger(
        to url: URL,
        preferences: ABI.AppPreferenceValues,
        parameters: ABI.AppConstants.Log,
        mapper: @escaping @Sendable (DebugLog.Line) -> String
    ) -> PartoutLogger {
        var builder = PartoutLogger.Builder()
        builder.configureLogging(
            to: url,
            preferences: preferences,
            parameters: parameters,
            mapper: mapper
        )
        builder.willPrint = {
            let prefix = "[\($0.profileId?.uuidString.prefix(8) ?? "GLOBAL")]"
            return "\(prefix) \($1)"
        }
        return builder.build()
    }

    func logPreamble(versionString: String, parameters: ABI.AppConstants.Log) {
        let level = parameters.options.maxDebugLogLevel
        appendLog(level, message: "")
        appendLog(level, message: "--- BEGIN ---")
        appendLog(level, message: "")

        let systemInfo = SystemInformation()
        appendLog(level, message: "App: \(versionString)")
        appendLog(level, message: "OS: \(systemInfo.osString)")
        if let deviceString = systemInfo.deviceString {
            appendLog(level, message: "Device: \(deviceString)")
        }
        appendLog(level, message: "")

        if let localLoggerURL {
            pspLog(.core, .debug, "Log to: \(localLoggerURL)")
        }
    }
}

private extension PartoutLogger.Builder {
    mutating func configureLogging(
        to url: URL,
        preferences: ABI.AppPreferenceValues,
        parameters: ABI.AppConstants.Log,
        mapper: @escaping @Sendable (DebugLog.Line) -> String
    ) {
        assertsMissingLoggingCategory = true
        var list: [LoggerCategory] = [
            .core,
            .os,
            .openvpn,
            .wireguard,
            .App.abi,
            .App.core,
            .App.iap,
            .App.profiles,
            .App.web
        ]
        list.append(.providers)
        setDefaultDestination(for: list)

        var newOptions = parameters.options
        if preferences.extensiveLogging {
            newOptions.maxLevel = .debug
        }
        setLocalLogger(
            url: url,
            options: newOptions.fromProto,
            mapper: mapper
        )
        if preferences.logsPrivateData {
            logsAddresses = true
            logsModules = true
        }
    }

    mutating func setDefaultDestination(for categories: [LoggerCategory]) {
        categories.forEach {
#if canImport(Darwin)
            setDestination(OSLogDestination($0), for: [$0])
#else
            setDestination(SimpleLogDestination(tag: "Passepartout"), for: [$0])
#endif
        }
    }
}

// MARK: - Mappers

private extension ABI.AppLogCategory {
    var partoutCategory: LoggerCategory {
        switch self {
        case .abi: .App.abi
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

private extension LoggerCategory {
    enum App {
        static let abi = LoggerCategory(appCategory: .abi)

        static let core = LoggerCategory(appCategory: .core)

        static let iap = LoggerCategory(appCategory: .iap)

        static let profiles = LoggerCategory(appCategory: .profiles)

        static let web = LoggerCategory(appCategory: .web)
    }

    init(appCategory: ABI.AppLogCategory) {
        self.init(rawValue: appCategory.id)
    }
}
