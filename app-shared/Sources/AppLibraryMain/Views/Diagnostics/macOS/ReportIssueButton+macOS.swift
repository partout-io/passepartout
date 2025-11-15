// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import CommonLibrary
import CommonResources
import SwiftUI

extension ReportIssueButton: View {
    var body: some View {
        Button(title) {
            modalRoute = .comment
        }
        .disabled(isPending)
        .themeModal(
            item: $modalRoute,
            options: ThemeModalOptions(size: .small),
            content: { _ in
                commentInputView()
            }
        )
    }
}

extension ReportIssueButton {

    @MainActor
    func sendEmail(comment: String) {
        Task {
            isPending = true
            defer {
                isPending = false
            }
            guard let service = NSSharingService(named: .composeEmail) else {
                isUnableToEmail = true
                return
            }
            let issue = await Issue.withMetadata(.init(
                ctx: .global,
                target: distributionTarget,
                versionString: BundleConfiguration.mainVersionString,
                purchasedProducts: purchasedProducts,
                providerLastUpdates: providerLastUpdates,
                tunnel: tunnel,
                urlForTunnelLog: Resources.constants.bundleURLForTunnelLog(in: distributionTarget),
                parameters: Resources.constants.log,
                comment: comment
            ))
            service.recipients = [issue.to]
            service.subject = issue.subject
            service.perform(withItems: issue.items)
        }
    }
}

private extension Issue {
    var items: [Any] {
        var list: [Any] = []
        list.append(body)
        if let appLog,
           let url = appLog.toTemporaryURL(withFilename: Resources.constants.log.appPath) {
            list.append(url)
        }
        if let tunnelLog,
           let url = tunnelLog.toTemporaryURL(withFilename: Resources.constants.log.tunnelPath) {
            list.append(url)
        }
        return list
    }
}

#endif
