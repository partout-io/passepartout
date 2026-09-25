// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppResources
import CommonLibrary
import Foundation

extension ABI.Issue {
    var body: String {
        return Resources.issueTemplate
            .replacingOccurrences(of: "$comment", with: comment)
            .replacingOccurrences(of: "$appLine", with: appLine ?? "unknown")
            .replacingOccurrences(of: "$osLine", with: osLine)
            .replacingOccurrences(of: "$deviceLine", with: deviceLine ?? "unknown")
            .replacingOccurrences(of: "$purchasedProducts", with: purchasedProducts.description)
    }
}

extension ABI.Issue {
    struct Metadata {
        let appConfiguration: ABI.AppConfiguration
        let purchasedProducts: Set<ABI.AppProduct>
        let tunnel: TunnelObservable
        let comment: String
    }

    static func withMetadata(_ metadata: Metadata) async -> ABI.Issue {
        let parameters = metadata.appConfiguration.constants.log
        let appLog = pspLogCurrent(parameters)
            .joined(separator: "\n")
            .data(using: .utf8)

        let tunnelLog: Data?

        // Live tunnel log
        let rawTunnelLog = await metadata.tunnel.currentLog()
        if !rawTunnelLog.isEmpty {
            tunnelLog = rawTunnelLog
                .joined(separator: "\n")
                .data(using: .utf8)
        }
        // Latest persisted tunnel log
        else if let latestTunnelEntry = pspLogEntriesAvailable(at: metadata.appConfiguration.urlForTunnelLog)
            .max(by: { $0.date < $1.date }) {
            tunnelLog = try? Data(contentsOf: latestTunnelEntry.url)
        }
        // Nothing
        else {
            tunnelLog = nil
        }

        var attachments: [ABI.IssueAttachment] = []
        if let appLog {
            attachments.append(.init(filename: metadata.appConfiguration.appLogPath, content: appLog))
        }
        if let tunnelLog {
            attachments.append(.init(filename: metadata.appConfiguration.tunnelLogPath, content: tunnelLog))
        }

        return ABI.Issue(
            comment: metadata.comment,
            appLine: "\(Strings.Unlocalized.appName) \(metadata.appConfiguration.bundle.versionString) [\(metadata.appConfiguration.bundle.distributionTarget.rawValue)]",
            purchasedProducts: metadata.purchasedProducts,
            attachments: attachments
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
