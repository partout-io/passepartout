// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public struct AppBundle: Decodable, Sendable {
        public let distributionTarget: ABI.DistributionTarget

        public let displayName: String
        public let versionNumber: String
        public let buildNumber: Int
        public var versionString: String {
            "\(versionNumber) (\(buildNumber))"
        }
        public let customUserLevel: AppUserLevel?
        public let bundleStrings: [String: String]

        public let appLogPath: String
        public let tunnelLogPath: String
        public let urlToAppLogs: URL
        public let urlToTunnelLogs: URL
        public let urlForReview: URL?
        public var urlForAppLog: URL {
            urlToAppLogs.appending(path: appLogPath)
        }
        public var urlForTunnelLog: URL {
            urlToTunnelLogs.appending(path: tunnelLogPath)
        }

        public init(distributionTarget: ABI.DistributionTarget, displayName: String, versionNumber: String, buildNumber: Int, customUserLevel: AppUserLevel?, bundleStrings: [String: String], appLogPath: String, tunnelLogPath: String, urlToAppLogs: URL, urlToTunnelLogs: URL, urlForReview: URL?) {
            self.distributionTarget = distributionTarget
            self.displayName = displayName
            self.versionNumber = versionNumber
            self.buildNumber = buildNumber
            self.customUserLevel = customUserLevel
            self.bundleStrings = bundleStrings
            self.appLogPath = appLogPath
            self.tunnelLogPath = tunnelLogPath
            self.urlToAppLogs = urlToAppLogs
            self.urlToTunnelLogs = urlToTunnelLogs
            self.urlForReview = urlForReview
        }

        // For previews
        public init(distributionTarget: ABI.DistributionTarget) {
            self.distributionTarget = distributionTarget

            displayName = "preview-display-name"
            versionNumber = "preview-1.2.3"
            buildNumber = 12345
            bundleStrings = [:]
            customUserLevel = nil

            let dummyURL = URL(fileURLWithPath: "")
            appLogPath = ""
            tunnelLogPath = ""
            urlToAppLogs = dummyURL
            urlToTunnelLogs = dummyURL
            urlForReview = dummyURL
        }
    }
}
