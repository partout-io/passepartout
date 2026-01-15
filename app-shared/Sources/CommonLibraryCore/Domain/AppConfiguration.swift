// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public enum BuildTarget: Sendable {
        case app
        case tunnel
    }

    public struct AppConfiguration: Sendable {
        public let constants: ABI.Constants
        public let distributionTarget: ABI.DistributionTarget

        public let displayName: String
        public let versionNumber: String
        public let buildNumber: Int
        public let versionString: String
        public let customUserLevel: AppUserLevel?
        public let bundleStrings: [String: String]

        public let urlForAppLog: URL
        public let urlForTunnelLog: URL
        public let urlForReview: URL?

        public init(constants: ABI.Constants, distributionTarget: ABI.DistributionTarget, displayName: String, versionNumber: String, buildNumber: Int, versionString: String, customUserLevel: AppUserLevel?, bundleStrings: [String: String], urlForAppLog: URL, urlForTunnelLog: URL, urlForReview: URL?) {
            self.constants = constants
            self.distributionTarget = distributionTarget
            self.displayName = displayName
            self.versionNumber = versionNumber
            self.buildNumber = buildNumber
            self.versionString = versionString
            self.customUserLevel = customUserLevel
            self.bundleStrings = bundleStrings
            self.urlForAppLog = urlForAppLog
            self.urlForTunnelLog = urlForTunnelLog
            self.urlForReview = urlForReview
        }

        // For previews
        public init(constants: Constants, distributionTarget: ABI.DistributionTarget) {
            self.constants = constants
            self.distributionTarget = distributionTarget

            displayName = "preview-display-name"
            versionNumber = "preview-1.2.3"
            buildNumber = 12345
            versionString = "preview-1.2.3-12345"
            bundleStrings = [:]
            customUserLevel = nil

            let dummyURL = URL(fileURLWithPath: "")
            urlForAppLog = dummyURL
            urlForTunnelLog = dummyURL
            urlForReview = dummyURL
        }
    }
}
