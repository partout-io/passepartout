// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS)

import CommonLibrary
import CommonUtils
import SwiftUI
import UIKit

extension ReportIssueButton: View {
    var body: some View {
        HStack {
            Button(title) {
                modalRoute = .comment
            }
            if isPending {
                Spacer()
                ProgressView()
            }
        }
        .disabled(isPending)
        .themeModal(item: $modalRoute) {
            switch $0 {
            case .comment:
                commentInputView()
            case .submit(let issue):
                emailComposerView(issue: issue)
            }
        }
    }
}

extension ReportIssueButton {
    func emailComposerView(issue: Issue) -> some View {
        MailComposerView(
            isPresented: Binding(presenting: $modalRoute) {
                switch $0 {
                case .submit:
                    return true
                default:
                    return false
                }
            },
            toRecipients: [issue.to],
            subject: issue.subject,
            messageBody: issue.body,
            attachments: issue.attachments
        )
    }

    @MainActor
    func sendEmail(comment: String) {
        Task {
            isPending = true
            defer {
                isPending = false
            }
            let issue = await Issue.withMetadata(.init(
                ctx: .global,
                target: distributionTarget,
                versionString: BundleConfiguration.mainVersionString,
                purchasedProducts: purchasedProducts,
                providerLastUpdates: providerLastUpdates,
                tunnel: tunnel,
                urlForTunnelLog: BundleConfiguration.urlForTunnelLog(in: distributionTarget),
                parameters: Constants.shared.log,
                comment: comment
            ))
            guard MailComposerView.canSendMail() else {
                openMailTo(with: issue)
                return
            }
            modalRoute = .submit(issue)
        }
    }

    func openMailTo(with issue: Issue) {
        guard let url = URL.mailto(to: issue.to, subject: issue.subject, body: issue.body) else {
            return
        }
        guard UIApplication.shared.canOpenURL(url) else {
            isUnableToEmail = true
            return
        }
        UIApplication.shared.open(url)
    }
}

private extension Issue {
    var attachments: [MailComposerView.Attachment] {
        var list: [MailComposerView.Attachment] = []
        let mimeType = Strings.Unlocalized.Issues.attachmentMimeType
        if let appLog {
            list.append(.init(data: appLog, mimeType: mimeType, fileName: Constants.shared.log.appPath))
        }
        if let tunnelLog {
            list.append(.init(data: tunnelLog, mimeType: mimeType, fileName: Constants.shared.log.tunnelPath))
        }
        return list
    }
}

#endif
