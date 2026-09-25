// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI.Issue {
    public init(
        comment: String,
        appLine: String?,
        purchasedProducts: Set<ABI.AppProduct>,
        attachments: [ABI.IssueAttachment] = []
    ) {
        let systemInfo = SystemInformation()
        self.init(
            id: UniqueID(),
            comment: comment,
            appLine: appLine,
            purchasedProducts: purchasedProducts
                .map(\.rawValue)
                .sorted(),
            attachments: attachments,
            osLine: systemInfo.osString,
            deviceLine: systemInfo.deviceString
        )
    }
}

extension ABI.Issue {
    public var appProducts: Set<ABI.AppProduct> {
        Set(
            purchasedProducts.compactMap {
                ABI.AppProduct(rawValue: $0)
            }
        )
    }
}
