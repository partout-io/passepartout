// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonUtils

extension ABI {
    public protocol AppProductHelper: InAppHelper where ProductType == AppProduct {
    }
}

extension StoreKitHelper: ABI.AppProductHelper where ProductType == ABI.AppProduct {
}
