// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProviderPicker: View {
    let providers: [Provider]

    @Binding
    var providerId: ProviderID?

    let isLoading: Bool

    @Binding
    var paywallReason: PaywallReason?

    var body: some View {
        Picker(selection: $providerId) {
            if !providers.isEmpty {
                Text(Strings.Views.Providers.selectProvider)
                    .tag(nil as ProviderID?)
                ForEach(providers, id: \.id) {
                    Text($0.description)
                        .tag($0.id as ProviderID?)
                }
            } else {
                Text(isLoading ? Strings.Global.Nouns.loading : Strings.Global.Nouns.none)
                    .tag(providerId) // tag always exists
            }
        } label: {
            HStack {
                Text(Strings.Global.Nouns.name)
                PurchaseRequiredView(
                    for: providerId,
                    reason: $paywallReason
                )
            }
        }
        .disabled(isLoading || providers.isEmpty)
    }
}
