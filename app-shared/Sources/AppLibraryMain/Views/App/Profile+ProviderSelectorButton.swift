// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension Profile {
    @MainActor
    func providerSelectorButton(onSelect: ((Profile) -> Void)?) -> some View {
        activeProviderModule
            .map { module in
                Button {
                    onSelect?(self)
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
