// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources
import Foundation

struct Dependencies {
    let appConfiguration: ABI.AppConfiguration
    let logFormatter: DateFormatter

    init(buildTarget: ABI.BuildTarget) {
        appConfiguration = Resources.newAppConfiguration(
            distributionTarget: Self.currentDistributionTarget,
            buildTarget: buildTarget
        )
        logFormatter = DateFormatter()
        logFormatter.dateFormat = appConfiguration.constants.log.formatter.timestamp
    }

    func formattedLog(timestamp: Date, message: String) -> String {
        let messageFormat = appConfiguration.constants.log.formatter.timestamp
        let formattedTimestamp = logFormatter.string(from: timestamp)
        return String(format: message, formattedTimestamp, messageFormat)
    }
}

private extension Dependencies {
    static var currentDistributionTarget: ABI.DistributionTarget {
#if PP_BUILD_MAC
        .developerID
#else
        .appStore
#endif
    }
}
