// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonUI
import CommonUtils

extension OriginalPurchase {
    public func isUntil(_ release: ABI.AppRelease) -> Bool {
        buildNumber <= release.build
    }
}
