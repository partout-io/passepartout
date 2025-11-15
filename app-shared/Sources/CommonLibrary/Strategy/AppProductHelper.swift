// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public protocol AppProductHelper: InAppHelper where ProductType == ABI.AppProduct {
}

extension StoreKitHelper: AppProductHelper where ProductType == ABI.AppProduct {
}
