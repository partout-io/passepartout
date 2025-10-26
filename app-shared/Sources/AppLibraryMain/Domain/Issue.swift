// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

struct Issue: Identifiable {
    let id: UUID

    let comment: String

    let appLine: String?

    let purchasedProducts: Set<AppProduct>

    let providerLastUpdates: [ProviderID: Timestamp]

    let appLog: Data?

    let tunnelLog: Data?

    let osLine: String

    let deviceLine: String?

    init(
        comment: String,
        appLine: String?,
        purchasedProducts: Set<AppProduct>,
        providerLastUpdates: [ProviderID: Timestamp] = [:],
        appLog: Data? = nil,
        tunnelLog: Data? = nil
    ) {
        id = UUID()
        self.comment = comment
        self.appLine = appLine
        self.purchasedProducts = purchasedProducts
        self.appLog = appLog
        self.tunnelLog = tunnelLog
        self.providerLastUpdates = providerLastUpdates

        let systemInfo = SystemInformation()
        osLine = systemInfo.osString
        deviceLine = systemInfo.deviceString
    }

    var body: String {
        let providers = providerLastUpdates.mapValues {
            $0.date.localizedDescription(style: .timestamp)
        }
        return template
            .replacingOccurrences(of: "$comment", with: comment)
            .replacingOccurrences(of: "$appLine", with: appLine ?? "unknown")
            .replacingOccurrences(of: "$osLine", with: osLine)
            .replacingOccurrences(of: "$deviceLine", with: deviceLine ?? "unknown")
            .replacingOccurrences(of: "$providerLastUpdates", with: providers.description)
            .replacingOccurrences(of: "$purchasedProducts", with: purchasedProducts.map(\.rawValue).description)
    }
}

private extension Issue {
    var template: String {
        do {
            guard let templateURL = Bundle.module.url(forResource: "Issue", withExtension: "txt") else {
                fatalError("Unable to find Issue.txt in Resources")
            }
            return try String(contentsOf: templateURL)
        } catch {
            fatalError("Unable to parse Issue.txt: \(error)")
        }
    }
}
