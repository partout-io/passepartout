// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI.AppBundle {
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
        appLogsURL = dummyURL
        tunnelLogsURL = dummyURL
        reviewURL = dummyURL
    }

    public var versionString: String {
        "\(versionNumber) (\(buildNumber))"
    }

    public var urlForAppLog: URL {
        appLogsURL.appending(path: appLogPath)
    }

    public var urlForTunnelLog: URL {
        tunnelLogsURL.appending(path: tunnelLogPath)
    }
}
