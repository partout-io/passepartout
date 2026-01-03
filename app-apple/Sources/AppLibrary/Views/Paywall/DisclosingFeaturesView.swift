// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct DisclosingFeaturesView: View {
    private let product: ABI.AppProduct

    private let requiredFeatures: Set<ABI.AppFeature>

    @Binding
    private var isDisclosing: Bool

    init(
        product: ABI.AppProduct,
        requiredFeatures: Set<ABI.AppFeature>,
        isDisclosing: Binding<Bool>
    ) {
        self.product = product
        self.requiredFeatures = requiredFeatures
        _isDisclosing = isDisclosing
    }

    var body: some View {
        Group {
            discloseButton
            featuresList
                .if(isDisclosing)
        }
        .font(.subheadline)
    }
}

private extension DisclosingFeaturesView {
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
        ForEach(product.features.sorted(), id: \.id) {
            FeatureRow(
                feature: $0,
                flags: requiredFeatures.contains($0) ? [.highlighted] : []
            )
        }
        .themeSection()
    }
}
