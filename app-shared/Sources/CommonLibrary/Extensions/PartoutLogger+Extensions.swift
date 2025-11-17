// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension PartoutLogger {
    public enum Target {
        case app
        case tunnelGlobal
        case tunnelProfile(Profile.ID)
    }

    private static var isDefaultLoggerRegistered = false

    @discardableResult
    public static func register(
        for target: Target,
        with cfg: ABI.AppConfiguration,
        preferences: ABI.AppPreferenceValues
    ) -> PartoutLoggerContext {
        switch target {
        case .app:
            if !isDefaultLoggerRegistered {
                isDefaultLoggerRegistered = true
                let logger = appLogger(
                    to: cfg.urlForAppLog,
                    preferences: preferences,
                    parameters: cfg.constants.log
                )
                PartoutLogger.register(logger)
                logger.logPreamble(versionString: cfg.versionString, parameters: cfg.constants.log)
            }
            return .global
        case .tunnelGlobal:
            let logger = tunnelLogger(
                to: cfg.urlForTunnelLog,
                preferences: preferences,
                parameters: cfg.constants.log
            )
            PartoutLogger.register(logger)
            logger.logPreamble(versionString: cfg.versionString, parameters: cfg.constants.log)
            return .global
        case .tunnelProfile(let profileId):
            if !isDefaultLoggerRegistered {
                isDefaultLoggerRegistered = true
                let logger = tunnelLogger(
                    to: cfg.urlForTunnelLog,
                    preferences: preferences,
                    parameters: cfg.constants.log
                )
                PartoutLogger.register(logger)
                logger.logPreamble(versionString: cfg.versionString, parameters: cfg.constants.log)
            }
            return PartoutLoggerContext(profileId)
        }
    }
}

private extension PartoutLogger {
    static func appLogger(
        to url: URL,
        preferences: ABI.AppPreferenceValues,
        parameters: ABI.Constants.Log
    ) -> PartoutLogger {
        var builder = PartoutLogger.Builder()
        builder.configureLogging(
            to: url,
            parameters: parameters,
            logsPrivateData: preferences.logsPrivateData
        )
        return builder.build()
    }

    static func tunnelLogger(
        to url: URL,
        preferences: ABI.AppPreferenceValues,
        parameters: ABI.Constants.Log
    ) -> PartoutLogger {
        var builder = PartoutLogger.Builder()
        builder.configureLogging(
            to: url,
            parameters: parameters,
            logsPrivateData: preferences.logsPrivateData
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
        currentLogLines(
            sinceLast: parameters.sinceLast,
            maxLevel: parameters.options.maxLevel
        )
        .map(parameters.formatter.formattedLine)
    }
}

private extension PartoutLogger.Builder {
    mutating func configureLogging(to url: URL, parameters: ABI.Constants.Log, logsPrivateData: Bool) {
        assertsMissingLoggingCategory = true
        setOSLog(for: [
            .core,
            .os,
            .openvpn,
            .providers,
            .wireguard,
            .App.core,
            .App.iap,
            .App.profiles,
            .App.web
        ])

        setLocalLogger(
            url: url,
            options: parameters.options,
            mapper: parameters.formatter.formattedLine
        )

        if logsPrivateData {
            logsAddresses = true
            logsModules = true
        }
    }

    mutating func setOSLog(for categories: [LoggerCategory]) {
        categories.forEach {
            setDestination(OSLogDestination($0), for: [$0])
        }
    }
}
