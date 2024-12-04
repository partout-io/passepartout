//
//  PurchasedView.swift
//  Passepartout
//
//  Created by Davide De Rosa on 11/25/24.
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

import CommonLibrary
import CommonUtils
import SwiftUI

public struct PurchasedView: View {

    @EnvironmentObject
    private var iapManager: IAPManager

    @State
    private var isLoading = true

    @State
    private var products: [InAppProduct] = []

    @StateObject
    private var errorHandler: ErrorHandler = .default()

    public init() {
    }

    public var body: some View {
        contentView
            .withErrorHandler(errorHandler)
            .themeProgress(if: isLoading)
            .themeAnimation(on: isLoading, category: .diagnostics)
            .onLoad {
                Task {
                    do {
                        products = try await iapManager
                            .purchasableProducts(for: Array(iapManager.purchasedProducts))
                            .sorted {
                                $0.localizedTitle < $1.localizedTitle
                            }
                        isLoading = false
                    } catch {
                        errorHandler.handle(error)
                        isLoading = false
                    }
                }
            }
    }
}

private extension PurchasedView {
    var isEmpty: Bool {
        iapManager.purchasedAppBuild == nil && iapManager.purchasedProducts.isEmpty && iapManager.eligibleFeatures.isEmpty
    }

    var allFeatures: [AppFeature] {
        AppFeature.allCases.sorted {
            let lRank = $0.rank(with: iapManager)
            let rRank = $1.rank(with: iapManager)
            if lRank != rRank {
                return lRank < rRank
            }
            return $0 < $1
        }
    }
}

private extension PurchasedView {
    var contentView: some View {
#if os(macOS)
        Form(content: sectionsGroup)
            .themeForm()
#else
        List(content: sectionsGroup)
#endif
    }

    func sectionsGroup() -> some View {
        Group {
            downloadSection
            productsSection
            featuresSection
        }
    }

    var downloadSection: some View {
        iapManager.purchasedAppBuild.map { build in
            Group {
                Text(Strings.Views.Purchased.Rows.buildNumber)
                    .themeTrailingValue(build.description)
                    .scrollableOnTV()
            }
            .themeSection(header: Strings.Views.Purchased.Sections.Download.header)
        }
    }

    var productsSection: some View {
        Group {
            if !products.isEmpty {
                ForEach(products, id: \.productIdentifier) {
                    Text($0.localizedTitle)
                        .themeTrailingValue($0.localizedPrice)
                        .scrollableOnTV()
                }
            } else {
                Text(Strings.Views.Purchased.noPurchases)
            }
        }
        .themeSection(header: Strings.Views.Purchased.Sections.Products.header)
    }

    var featuresSection: some View {
        Group {
            ForEach(allFeatures, id: \.self) { feature in
                FeatureView(text: feature.localizedDescription, isEligible: iapManager.isEligible(for: feature))
                    .scrollableOnTV()
            }
        }
        .themeSection(header: Strings.Views.Purchased.Sections.Features.header)
    }
}

private struct FeatureView: View {
    let text: String

    let isEligible: Bool

    var body: some View {
        HStack {
            Text(text)
            Spacer()
            ThemeImage(isEligible ? .marked : .close)
        }
        .foregroundStyle(isEligible ? .primary : .secondary)
    }
}

// MARK: -

private extension AppFeature {

    @MainActor
    func rank(with iapManager: IAPManager) -> Int {
        iapManager.isEligible(for: self) ? 0 : 1
    }
}

// MARK: - Previews

#Preview {
    PurchasedView()
        .withMockEnvironment()
}
