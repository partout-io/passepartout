// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppResources
import CommonLibrary

extension ABI.Issue {
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

extension ABI.Issue {
    struct Metadata {
        let ctx: PartoutLoggerContext

        let appConfiguration: ABI.AppConfiguration

        let purchasedProducts: Set<ABI.AppProduct>

        let providerLastUpdates: [ProviderID: Timestamp]

        let tunnel: TunnelManager

        let comment: String
    }

    @MainActor
    static func withMetadata(_ metadata: Metadata, formatter: @escaping LogFormatterBlock) async -> ABI.Issue {
        let parameters = metadata.appConfiguration.constants.log
        let appLog = metadata.ctx.logger.currentLog(parameters: parameters)
            .joined(separator: "\n")
            .data(using: .utf8)

        let tunnelLog: Data?

        // Live tunnel log
        let rawTunnelLog = await metadata.tunnel.currentLog(parameters: parameters)
        if !rawTunnelLog.isEmpty {
            tunnelLog = rawTunnelLog
                .map(formatter)
                .joined(separator: "\n")
                .data(using: .utf8)
        }
        // Latest persisted tunnel log
        else if let latestTunnelEntry = LocalLogger.FileStrategy()
            .availableLogs(at: metadata.appConfiguration.urlForTunnelLog)
            .max(by: { $0.key < $1.key }) {

            tunnelLog = try? Data(contentsOf: latestTunnelEntry.value)
        }
        // Nothing
        else {
            tunnelLog = nil
        }

        return ABI.Issue(
            comment: metadata.comment,
            appLine: "\(Strings.Unlocalized.appName) \(metadata.appConfiguration.versionString) [\(metadata.appConfiguration.distributionTarget.rawValue)]",
            purchasedProducts: metadata.purchasedProducts,
            providerLastUpdates: metadata.providerLastUpdates,
            appLog: appLog,
            tunnelLog: tunnelLog
        )
    }
}

extension ABI.Issue {
    func to(cfg: ABI.AppConfiguration) -> String {
        cfg.constants.emails.issues
    }

    var subject: String {
        Strings.Unlocalized.Issues.subject
    }
}
