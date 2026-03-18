// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI.AppBundle {
    public init(distributionTarget: ABI.DistributionTarget, displayName: String, versionNumber: String, buildNumber: Int, customUserLevel: ABI.AppUserLevel?, bundleStrings: [String: String], appLogPath: String, tunnelLogPath: String, urlToAppLogs: URL, urlToTunnelLogs: URL, urlForReview: URL?) {
        self.distributionTarget = distributionTarget
        self.displayName = displayName
        self.versionNumber = versionNumber
        self.buildNumber = buildNumber
        self.customUserLevel = customUserLevel
        self.bundleStrings = bundleStrings
        self.appLogPath = appLogPath
        self.tunnelLogPath = tunnelLogPath
        self.urlToAppLogs = urlToAppLogs.absoluteString
        self.urlToTunnelLogs = urlToTunnelLogs.absoluteString
        self.urlForReview = urlForReview?.absoluteString
    }

    // For previews
    public init(distributionTarget: ABI.DistributionTarget) {
        self.distributionTarget = distributionTarget

        displayName = "preview-display-name"
        versionNumber = "preview-1.2.3"
        buildNumber = 12345
        bundleStrings = [:]
        customUserLevel = nil

        let dummyURL = ""
        appLogPath = ""
        tunnelLogPath = ""
        urlToAppLogs = dummyURL
        urlToTunnelLogs = dummyURL
        urlForReview = dummyURL
    }

    public var versionString: String {
        "\(versionNumber) (\(buildNumber))"
    }

    public var urlForAppLog: URL {
        urlToAppLogsURL.appending(path: appLogPath)
    }

    public var urlForTunnelLog: URL {
        urlToTunnelLogsURL.appending(path: tunnelLogPath)
    }
}

// FIXME: #1723, Precompute in Quicktype decoding
private extension ABI.AppBundle {
    var urlToAppLogsURL: URL {
        URL(forceString: urlToAppLogs, description: "bundle.urlToAppLogs")
    }

    var urlToTunnelLogsURL: URL {
        URL(forceString: urlToTunnelLogs, description: "bundle.urlToTunnelLogs")
    }
}
