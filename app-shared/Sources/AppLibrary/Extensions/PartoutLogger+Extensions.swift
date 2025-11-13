// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension PartoutLogger {
    public enum Target {
        case app
        case tunnelGlobal(DistributionTarget)
        case tunnelProfile(Profile.ID, DistributionTarget)
    }

    private static var isDefaultLoggerRegistered = false

    @discardableResult
    public static func register(
        for target: Target,
        with preferences: AppPreferenceValues
    ) -> PartoutLoggerContext {
        switch target {
        case .app:
            if !isDefaultLoggerRegistered {
                isDefaultLoggerRegistered = true
                let logger = appLogger(preferences: preferences)
                PartoutLogger.register(logger)
                logger.logPreamble(parameters: Constants.shared.log)
            }
            return .global
        case .tunnelGlobal(let target):
            let logger = tunnelLogger(preferences: preferences, target: target)
            PartoutLogger.register(logger)
            logger.logPreamble(parameters: Constants.shared.log)
            return .global
        case .tunnelProfile(let profileId, let target):
            if !isDefaultLoggerRegistered {
                isDefaultLoggerRegistered = true
                let logger = tunnelLogger(preferences: preferences, target: target)
                PartoutLogger.register(logger)
                logger.logPreamble(parameters: Constants.shared.log)
            }
            return PartoutLoggerContext(profileId)
        }
    }
}

private extension PartoutLogger {
    static func appLogger(preferences: AppPreferenceValues) -> PartoutLogger {
        var builder = PartoutLogger.Builder()
        builder.configureLogging(
            to: BundleConfiguration.urlForAppLog,
            parameters: Constants.shared.log,
            logsPrivateData: preferences.logsPrivateData
        )
        return builder.build()
    }

    static func tunnelLogger(preferences: AppPreferenceValues, target: DistributionTarget) -> PartoutLogger {
        var builder = PartoutLogger.Builder()
        builder.configureLogging(
            to: BundleConfiguration.urlForTunnelLog(in: target),
            parameters: Constants.shared.log,
            logsPrivateData: preferences.logsPrivateData
        )
        builder.willPrint = {
            let prefix = "[\($0.profileId?.uuidString.prefix(8) ?? "GLOBAL")]"
            return "\(prefix) \($1)"
        }
        return builder.build()
    }

    func logPreamble(parameters: Constants.Log) {
        let level = parameters.options.maxLevel
        appendLog(level, message: "")
        appendLog(level, message: "--- BEGIN ---")
        appendLog(level, message: "")

        let systemInfo = SystemInformation()
        appendLog(level, message: "App: \(BundleConfiguration.mainVersionString)")
        appendLog(level, message: "OS: \(systemInfo.osString)")
        if let deviceString = systemInfo.deviceString {
            appendLog(level, message: "Device: \(deviceString)")
        }
        appendLog(level, message: "")

        if let localLoggerURL {
            pp_log(.global, .App.core, .debug, "Log to: \(localLoggerURL)")
        }
    }
}

extension PartoutLogger {
    public func currentLog(parameters: Constants.Log) -> [String] {
        currentLogLines(
            sinceLast: parameters.sinceLast,
            maxLevel: parameters.options.maxLevel
        )
        .map(parameters.formatter.formattedLine)
    }
}

private extension PartoutLogger.Builder {
    mutating func configureLogging(to url: URL, parameters: Constants.Log, logsPrivateData: Bool) {
        assertsMissingLoggingCategory = true
        setOSLog(for: [
            .core,
            .os,
            .openvpn,
            .providers,
            .wireguard,
            .App.core,
            .App.iap,
            .App.migration,
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
