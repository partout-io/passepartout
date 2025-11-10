// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonUtils

extension UI {
    public protocol AppProductHelper: InAppHelper where ProductType == AppProduct {
    }
}

extension StoreKitHelper: UI.AppProductHelper where ProductType == UI.AppProduct {
}
