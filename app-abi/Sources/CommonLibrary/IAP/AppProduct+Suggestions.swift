// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension UI.AppProduct {

    // if the intersection between the required features and this product's
    // features is empty, it means that purchasing this product is redundant
    // in that the required features would be equal after the purchase
    public func isRedundant(forRequiredFeatures requiredFeatures: Set<UI.AppFeature>) -> Bool {
        Set(features).isDisjoint(with: requiredFeatures)
    }
}
