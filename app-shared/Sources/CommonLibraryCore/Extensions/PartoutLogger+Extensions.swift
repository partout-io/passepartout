// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: #1594, Drop import (wrap PartoutLogger)
import Partout

extension PartoutLogger {
    public enum Target {
        case app
        case tunnelGlobal
        case tunnelProfile(Profile.ID)
    }

    nonisolated(unsafe)
    private static var isDefaultLoggerRegistered = false

    @discardableResult
    public static func register(
        for target: Target,
        with appConfiguration: ABI.AppConfiguration,
        preferences: ABI.AppPreferenceValues,
        mapper: @escaping @Sendable (DebugLog.Line) -> String
    ) -> PartoutLoggerContext {
        switch target {
        case .app:
            if !isDefaultLoggerRegistered {
                isDefaultLoggerRegistered = true
                let logger = appLogger(
                    to: appConfiguration.urlForAppLog,
                    preferences: preferences,
                    parameters: appConfiguration.constants.log,
                    mapper: mapper
                )
                PartoutLogger.register(logger)
                logger.logPreamble(
                    versionString: appConfiguration.versionString,
                    parameters: appConfiguration.constants.log
                )
            }
            return .global
        case .tunnelGlobal:
            let logger = tunnelLogger(
                to: appConfiguration.urlForTunnelLog,
                preferences: preferences,
                parameters: appConfiguration.constants.log,
                mapper: mapper
            )
            PartoutLogger.register(logger)
            logger.logPreamble(
                versionString: appConfiguration.versionString,
                parameters: appConfiguration.constants.log
            )
            return .global
        case .tunnelProfile(let profileId):
            if !isDefaultLoggerRegistered {
                isDefaultLoggerRegistered = true
                let logger = tunnelLogger(
                    to: appConfiguration.urlForTunnelLog,
                    preferences: preferences,
                    parameters: appConfiguration.constants.log,
                    mapper: mapper
                )
                PartoutLogger.register(logger)
                logger.logPreamble(
                    versionString: appConfiguration.versionString,
                    parameters: appConfiguration.constants.log
                )
            }
            return PartoutLoggerContext(profileId)
        }
    }
}

private extension PartoutLogger {
    static func appLogger(
        to url: URL,
        preferences: ABI.AppPreferenceValues,
        parameters: ABI.Constants.Log,
        mapper: @escaping @Sendable (DebugLog.Line) -> String
    ) -> PartoutLogger {
        var builder = PartoutLogger.Builder()
        builder.configureLogging(
            to: url,
            parameters: parameters,
            logsPrivateData: preferences.logsPrivateData,
            mapper: mapper
        )
        return builder.build()
    }

    static func tunnelLogger(
        to url: URL,
        preferences: ABI.AppPreferenceValues,
        parameters: ABI.Constants.Log,
        mapper: @escaping @Sendable (DebugLog.Line) -> String
    ) -> PartoutLogger {
        var builder = PartoutLogger.Builder()
        builder.configureLogging(
            to: url,
            parameters: parameters,
            logsPrivateData: preferences.logsPrivateData,
            mapper: mapper
        )
        builder.willPrint = {
            let prefix = "[\($0.profileId?.uuidString.prefix(8) ?? "GLOBAL")]"
            return "\(prefix) \($1)"
        }
        return builder.build()
    }

    func logPreamble(versionString: String, parameters: ABI.Constants.Log) {
        let level = parameters.options.maxLevel
        appendLog(level, message: "")
        appendLog(level, message: "--- BEGIN ---")
        appendLog(level, message: "")

        let systemInfo = ABI.SystemInformation()
        appendLog(level, message: "App: \(versionString)")
        appendLog(level, message: "OS: \(systemInfo.osString)")
        if let deviceString = systemInfo.deviceString {
            appendLog(level, message: "Device: \(deviceString)")
        }
        appendLog(level, message: "")

        if let localLoggerURL {
            pp_log_g(.App.core, .debug, "Log to: \(localLoggerURL)")
        }
    }
}

extension PartoutLogger {
    public func currentLog(parameters: ABI.Constants.Log) -> [String] {
        currentLog(sinceLast: parameters.sinceLast, maxLevel: parameters.options.maxLevel)
    }
}

private extension PartoutLogger.Builder {
    mutating func configureLogging(
        to url: URL,
        parameters: ABI.Constants.Log,
        logsPrivateData: Bool,
        mapper: @escaping @Sendable (DebugLog.Line) -> String
    ) {
        assertsMissingLoggingCategory = true
        var list: [LoggerCategory] = [
            .core,
            .os,
            .openvpn,
            .wireguard,
            .App.core,
            .App.iap,
            .App.profiles,
            .App.web
        ]
        list.append(.App.providers)
        setDefaultDestination(for: list)

        setLocalLogger(
            url: url,
            options: parameters.options,
            mapper: mapper
        )

        if logsPrivateData {
            logsAddresses = true
            logsModules = true
        }
    }

    mutating func setDefaultDestination(for categories: [LoggerCategory]) {
        categories.forEach {
#if canImport(Darwin)
            setDestination(OSLogDestination($0), for: [$0])
#else
            setDestination(SimpleLogDestination(), for: [$0])
#endif
        }
    }
}
