// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS)

import CommonLibrary
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

@MainActor
extension ReportIssueButton {
    func emailComposerView(issue: ABI.Issue) -> some View {
        MailComposerView(
            isPresented: Binding(presenting: $modalRoute) {
                switch $0 {
                case .submit:
                    return true
                default:
                    return false
                }
            },
            toRecipients: [issue.to(cfg: appConfiguration)],
            subject: issue.subject,
            messageBody: issue.body,
            attachments: issue.mailComposerAttachments()
        )
    }

    func sendEmail(comment: String) {
        Task {
            isPending = true
            defer {
                isPending = false
            }
            let issue = await ABI.Issue.withMetadata(.init(
                appConfiguration: appConfiguration,
                purchasedProducts: purchasedProducts,
                providerLastUpdates: providerLastUpdates,
                tunnel: tunnel,
                comment: comment
            ))
            guard MailComposerView.canSendMail() else {
                openMailTo(with: issue)
                return
            }
            modalRoute = .submit(issue)
        }
    }

    func openMailTo(with issue: ABI.Issue) {
        guard let url = URL.mailto(to: issue.to(cfg: appConfiguration), subject: issue.subject, body: issue.body) else {
            return
        }
        guard UIApplication.shared.canOpenURL(url) else {
            isUnableToEmail = true
            return
        }
        UIApplication.shared.open(url)
    }
}

private extension ABI.Issue {
    func mailComposerAttachments() -> [MailComposerView.Attachment] {
        let mimeType = Strings.Unlocalized.Issues.attachmentMimeType
        return attachments.map {
            .init(data: $0.content, mimeType: mimeType, fileName: $0.filename)
        }
    }
}

#endif
