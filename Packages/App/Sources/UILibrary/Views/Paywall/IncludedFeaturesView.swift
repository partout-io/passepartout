//
//  IncludedFeaturesView.swift
//  Passepartout
//
//  Created by Davide De Rosa on 2/18/25.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
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

import CommonIAP
import CommonLibrary
import CommonUtils
import SwiftUI

public struct IncludedFeaturesView: View {
    private let product: AppProduct

    private let highlightedFeatures: Set<AppFeature>

    @Binding
    private var isDisclosing: Bool

    public init(
        product: AppProduct,
        highlightedFeatures: Set<AppFeature>,
        isDisclosing: Binding<Bool>
    ) {
        self.product = product
        self.highlightedFeatures = highlightedFeatures
        _isDisclosing = isDisclosing
    }

    public var body: some View {
        Group {
            discloseButton
                .padding(.top, 8)
            featuresList
                .if(isDisclosing)
        }
        .font(.subheadline)
    }
}

private extension IncludedFeaturesView {
    var discloseButton: some View {
        Button {
            isDisclosing.toggle()
        } label: {
            HStack {
                Text(Strings.Views.Paywall.Product.includedFeatures)
                ThemeImage(isDisclosing ? .undisclose : .disclose)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .cursor(.hand)
    }

    var featuresList: some View {
        FeatureListView(style: .list, features: product.features) {
            IncludedFeatureRow(feature: $0, isHighlighted: highlightedFeatures.contains($0))
        }
    }
}
