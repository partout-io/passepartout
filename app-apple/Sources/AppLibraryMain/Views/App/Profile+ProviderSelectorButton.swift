// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension ABI.AppProfile {
    @MainActor
    func providerSelectorButton(onSelect: ((Profile) -> Void)?) -> some View {
        native
            .activeProviderModule
            .map { module in
                Button {
                    onSelect?(native)
                } label: {
                    ProviderCountryFlag(entity: module.entity?.header)
                }
                .buttonStyle(.plain)
            }
    }
}

private struct ProviderCountryFlag: View {
    let entity: ProviderEntity.Header?

    var body: some View {
        ThemeCountryFlag(
            entity?.countryCode,
            placeholderTip: Strings.Errors.App.Passepartout.missingProviderEntity,
            countryTip: {
                $0.localizedAsRegionCode
            }
        )
    }
}
