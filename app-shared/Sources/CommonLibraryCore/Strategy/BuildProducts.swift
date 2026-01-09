// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public typealias BuildProducts = @Sendable (_ purchase: ABI.OriginalPurchase) -> Set<ABI.AppProduct>
