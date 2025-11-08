// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension AppFeature {

    // some non-essential features can only be purchased individually
    // here we suggest the products entitling for such features
    public var nonEssentialProducts: Set<AppProduct> {
        switch self {
        case .appleTV:
            return [.Features.appleTV]
        default:
            assert(isEssential, "Non-essential feature \(rawValue) must suggest a purchasable product")
            return []
        }
    }
}
