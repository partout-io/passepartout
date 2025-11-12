// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public typealias BuildProducts<ProductType> = @Sendable (_ purchase: OriginalPurchase) -> Set<ProductType> where ProductType: Hashable
