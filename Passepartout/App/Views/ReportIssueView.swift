//
//  ReportIssueView.swift
//  Passepartout
//
//  Created by Davide De Rosa on 3/24/22.
//  Copyright (c) 2023 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

#if !os(tvOS)
import MessageUI
import PassepartoutLibrary
import SwiftUI

struct ReportIssueView: View {
    @Binding private var isPresented: Bool

    private let toRecipients: [String]

    private let subject: String

    private let messageBody: String

    private let attachments: [MailComposerView.Attachment]

    init(
        isPresented: Binding<Bool>,
        vpnProtocol: VPNProtocolType,
        logURLs: [URL],
        providerMetadata: ProviderMetadata? = nil,
        lastUpdate: Date? = nil,
        purchasedProductIdentifiers: Set<String>? = nil
    ) {
        _isPresented = isPresented

        toRecipients = [Unlocalized.Issues.recipient]
        subject = Unlocalized.Issues.subject

        let bodyContent = Unlocalized.Issues.template
        var bodyMetadata = "--\n\n"
        bodyMetadata += DebugLog(content: "").decoratedString()

        if let providerMetadata {
            bodyMetadata += "Provider: \(providerMetadata.fullName)\n"
            if let lastUpdate {
                bodyMetadata += "Last updated: \(lastUpdate)\n"
            }
            bodyMetadata += "\n"
        }
        if let purchasedProductIdentifiers {
            bodyMetadata += "Purchased: \(purchasedProductIdentifiers)\n"
            bodyMetadata += "\n"
        }
        bodyMetadata += "--"
        messageBody = Unlocalized.Issues.body(bodyContent, bodyMetadata)

        attachments = logURLs.map {
            let logContent = $0.trailingContent(bytes: Unlocalized.Issues.maxLogBytes)
            let attachment = DebugLog(content: logContent).decoratedData()

            return MailComposerView.Attachment(
                data: attachment,
                mimeType: Unlocalized.Issues.MIME.debugLog,
                fileName: Unlocalized.Issues.Filenames.debugLog
            )
        }
    }

    var body: some View {
        MailComposerView(
            isPresented: $isPresented,
            toRecipients: toRecipients,
            subject: subject,
            messageBody: messageBody,
            attachments: attachments
        )
    }
}
#endif
