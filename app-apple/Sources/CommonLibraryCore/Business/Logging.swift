// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public let pspLogFileStrategy = LocalLogger.FileStrategy()

public func pspLog(
    _ category: ABI.AppLogCategory,
    _ level: ABI.AppLogLevel,
    _ message: @autoclosure () -> String
) {
    pspLog(nil, category, level, message())
}

public func pspLog(
    _ profileId: Profile.ID?,
    _ category: ABI.AppLogCategory,
    _ level: ABI.AppLogLevel,
    _ message: @autoclosure () -> String
) {
    pp_log_id(profileId, category.partoutCategory, level.partoutLevel, message())
}

public func pspLogLevel(
    extensiveLogging: Bool,
    defaultLevel: DebugLog.Level
) -> DebugLog.Level {
    extensiveLogging ? .debug : defaultLevel
}

public func pspLogCurrent(_ parameters: ABI.AppConstants.Log) -> [String] {
    let logger = PartoutLogger.default
    return logger.currentLog(
        sinceLast: parameters.sinceLast,
        maxLevel: logger.maxLevel
    )
}

public func pspLogFlush() {
    PartoutLogger.default.flushLog()
}

public func pspLogEntriesAvailable(at url: URL) -> [ABI.LogEntry] {
    pspLogFileStrategy
        .availableLogs(at: url)
        .sorted {
            $0.key > $1.key
        }
        .map {
            ABI.LogEntry(date: $0, url: $1)
        }
}

public func pspLogEntriesPurge(at url: URL) {
    pspLogFileStrategy
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
    preferences: AppPreferencesStore,
    localURL: URL?,
    localMapper: (@Sendable (DebugLog.Line) -> String)?
) -> PartoutLoggerContext {
    switch target {
    case .app:
        let replacing = isDefaultLoggerRegistered
        isDefaultLoggerRegistered = true
        let logger = PartoutLogger.logger(
            preferences: preferences,
            parameters: appConfiguration.constants.log,
            localURL: localURL,
            localMapper: localMapper
        )
        PartoutLogger.register(logger, preservingLog: !replacing || preferences[\.logsPrivateData])
        if replacing, !preferences[\.logsPrivateData] {
            do {
                try logger.resetLog()
            } catch {
                pspLog(.app, .error, "Unable to reset current log: \(error)")
            }
        }
        logger.logPreamble(
            versionString: appConfiguration.bundle.versionString,
            parameters: appConfiguration.constants.log
        )
        return .global
    case .tunnelGlobal:
        isDefaultLoggerRegistered = false
        let logger = PartoutLogger.logger(
            preferences: preferences,
            parameters: appConfiguration.constants.log,
            localURL: localURL,
            localMapper: localMapper,
            messageFormatter: tunnelLogMessage
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
            let logger = PartoutLogger.logger(
                preferences: preferences,
                parameters: appConfiguration.constants.log,
                localURL: localURL,
                localMapper: localMapper,
                messageFormatter: tunnelLogMessage
            )
            PartoutLogger.register(logger)
        }
        return PartoutLoggerContext(profileId)
    }
}

/// Format profile context consistently for Swift and native records.
func tunnelLogMessage(_ context: PartoutLoggerContext, _ message: String) -> String {
    let prefix = "[\(context.profileId?.uuidString.prefix(8) ?? "GLOBAL")]"
    return "\(prefix) \(message)"
}

// MARK: - Helpers

private extension PartoutLogger {
    static func logger(
        preferences: AppPreferencesStore,
        parameters: ABI.AppConstants.Log,
        localURL: URL?,
        localMapper: (@Sendable (DebugLog.Line) -> String)?,
        messageFormatter: PartoutLogger.PrintFunction? = nil
    ) -> PartoutLogger {
        var builder = PartoutLogger.Builder()
        builder.configureLogging(
            preferences: preferences,
            parameters: parameters,
            localURL: localURL,
            localMapper: localMapper
        )
        if let messageFormatter { builder.willPrint = messageFormatter }
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
            pspLog(.app, .debug, "Log to: \(localLoggerURL)")
        }
    }
}

extension PartoutLogger.Builder {
    mutating func configureLogging(
        preferences: AppPreferencesStore,
        parameters: ABI.AppConstants.Log,
        localURL: URL?,
        localMapper: (@Sendable (DebugLog.Line) -> String)?
    ) {
        assertsMissingLoggingCategory = true
        let list = LoggerCategory.allCases
            + ABI.AppLogCategory.allCases.map(\.partoutCategory)
        setDefaultDestination(for: list, tag: parameters.tag)

        var newOptions = parameters.options
        maxLevel = pspLogLevel(
            extensiveLogging: preferences[\.extensiveLogging],
            defaultLevel: newOptions.maxDebugLogLevel
        )
        newOptions.maxLevel = .init(rawValue: maxLevel.rawValue) ?? newOptions.maxLevel
        if let localURL, let localMapper {
            setLocalLogger(
                url: localURL,
                options: newOptions.fromProto,
                mapper: localMapper
            )
        }
        if preferences[\.logsPrivateData] {
            logsAddresses = true
            logsModules = true
            logsRawBytes = false
        }
    }

    mutating func setDefaultDestination(for categories: [LoggerCategory], tag: String) {
        categories.forEach {
#if canImport(Darwin)
            setDestination(OSLogDestination($0), for: [$0])
#else
            setDestination(SimpleLogDestination(tag: tag), for: [$0])
#endif
        }
    }
}

// MARK: - Mappers

private extension ABI.AppLogCategory {
    var partoutCategory: LoggerCategory {
        LoggerCategory(rawValue: id)
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
