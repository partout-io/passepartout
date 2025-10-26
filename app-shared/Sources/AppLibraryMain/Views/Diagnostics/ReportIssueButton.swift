// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ReportIssueButton {

    @Environment(\.distributionTarget)
    var distributionTarget: DistributionTarget

    let title: String

    var message: String?

    let tunnel: ExtendedTunnel

    let apiManager: APIManager

    let purchasedProducts: Set<AppProduct>

    @Binding
    var isUnableToEmail: Bool

    @State
    var isPending = false

    @State
    var modalRoute: ModalRoute?
}

extension ReportIssueButton {
    enum ModalRoute: Identifiable {
        case comment

        case submit(Issue)

        var id: Int {
            switch self {
            case .comment: return 1
            case .submit: return 2
            }
        }
    }

    func commentInputView() -> some View {
        ThemeTextInputView(
            Strings.Views.Diagnostics.ReportIssue.title,
            message: message,
            isPresented: Binding(presenting: $modalRoute) {
                switch $0 {
                case .comment:
                    return true
                default:
                    return false
                }
            },
            onValidate: {
                !$0.isEmpty
            },
            onSubmit: {
                sendEmail(comment: $0)
            }
        )
    }
}

@MainActor
extension ReportIssueButton {
    var providerLastUpdates: [ProviderID: Timestamp] {
        apiManager.cache.compactMapValues(\.lastUpdate)
    }
}
