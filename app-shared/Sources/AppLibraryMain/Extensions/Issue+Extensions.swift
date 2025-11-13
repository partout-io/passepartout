// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources
import Foundation

extension Issue {
    var body: String {
        let providers = providerLastUpdates.mapValues {
            $0.date.localizedDescription(style: .timestamp)
        }
        return Resources.issueTemplate
            .replacingOccurrences(of: "$comment", with: comment)
            .replacingOccurrences(of: "$appLine", with: appLine ?? "unknown")
            .replacingOccurrences(of: "$osLine", with: osLine)
            .replacingOccurrences(of: "$deviceLine", with: deviceLine ?? "unknown")
            .replacingOccurrences(of: "$providerLastUpdates", with: providers.description)
            .replacingOccurrences(of: "$purchasedProducts", with: purchasedProducts.map(\.rawValue).description)
    }
}

extension Issue {
    struct Metadata {
        let ctx: PartoutLoggerContext

        let target: DistributionTarget

        let versionString: String

        let purchasedProducts: Set<AppProduct>

        let providerLastUpdates: [ProviderID: Timestamp]

        let tunnel: ExtendedTunnel

        let urlForTunnelLog: URL

        let parameters: Constants.Log

        let comment: String
    }

    @MainActor
    static func withMetadata(_ metadata: Metadata) async -> Issue {
        let appLog = metadata.ctx.logger.currentLog(parameters: metadata.parameters)
            .joined(separator: "\n")
            .data(using: .utf8)

        let tunnelLog: Data?

        // live tunnel log
        let rawTunnelLog = await metadata.tunnel.currentLog(parameters: metadata.parameters)
        if !rawTunnelLog.isEmpty {
            tunnelLog = rawTunnelLog
                .joined(separator: "\n")
                .data(using: .utf8)
        }
        // latest persisted tunnel log
        else if let latestTunnelEntry = LocalLogger.FileStrategy()
            .availableLogs(at: metadata.urlForTunnelLog)
            .max(by: { $0.key < $1.key }) {

            tunnelLog = try? Data(contentsOf: latestTunnelEntry.value)
        }
        // nothing
        else {
            tunnelLog = nil
        }

        return Issue(
            comment: metadata.comment,
            appLine: "\(Strings.Unlocalized.appName) \(metadata.versionString) [\(metadata.target.rawValue)]",
            purchasedProducts: metadata.purchasedProducts,
            providerLastUpdates: metadata.providerLastUpdates,
            appLog: appLog,
            tunnelLog: tunnelLog
        )
    }
}

extension Issue {
    var to: String {
        Resources.constants.emails.issues
    }

    var subject: String {
        Strings.Unlocalized.Issues.subject
    }
}
