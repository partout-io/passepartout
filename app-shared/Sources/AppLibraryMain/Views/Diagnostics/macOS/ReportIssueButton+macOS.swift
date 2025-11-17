// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import CommonLibrary
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
            let issue = await ABI.Issue.withMetadata(.init(
                ctx: .global,
                appConfiguration: appConfiguration,
                purchasedProducts: purchasedProducts,
                providerLastUpdates: providerLastUpdates,
                tunnel: tunnel,
                comment: comment
            ))
            service.recipients = [issue.to(cfg: appConfiguration)]
            service.subject = issue.subject
            service.perform(withItems: issue.items(cfg: appConfiguration))
        }
    }
}

private extension ABI.Issue {
    func items(cfg: ABI.AppConfiguration) -> [Any] {
        var list: [Any] = []
        list.append(body)
        if let appLog,
           let url = appLog.toTemporaryURL(withFilename: cfg.constants.log.appPath) {
            list.append(url)
        }
        if let tunnelLog,
           let url = tunnelLog.toTemporaryURL(withFilename: cfg.constants.log.tunnelPath) {
            list.append(url)
        }
        return list
    }
}

#endif
