// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public typealias BuildProducts<ProductType> = @Sendable (_ purchase: OriginalPurchase) -> Set<ProductType> where ProductType: Hashable
