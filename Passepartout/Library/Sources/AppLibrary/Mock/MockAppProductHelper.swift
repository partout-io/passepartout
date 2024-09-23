//
//  MockAppProductHelper.swift
//  Passepartout
//
//  Created by Davide De Rosa on 12/19/23.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import UtilsLibrary

actor MockAppProductHelper: AppProductHelper {
    private(set) var products: [AppProduct: InAppProduct]

    init() {
        products = [:]
    }

    nonisolated var canMakePurchases: Bool {
        true
    }

    func fetchProducts() async throws {
        products = AppProduct.all.reduce(into: [:]) {
            $0[$1] = InAppProduct(
                productIdentifier: $1.rawValue,
                localizedTitle: $1.rawValue,
                localizedPrice: "10.0",
                native: $1
            )
        }
    }

    func purchase(productWithIdentifier productIdentifier: AppProduct) async throws -> InAppPurchaseResult {
        .done
    }

    func restorePurchases() async throws {
    }
}
