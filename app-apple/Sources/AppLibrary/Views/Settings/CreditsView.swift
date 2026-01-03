// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppResources
import CommonLibrary
import SwiftUI

public struct CreditsView: View {
    public init() {
    }

    public var body: some View {
        GenericCreditsView(
            credits: Resources.credits,
            licensesHeader: Strings.Views.Settings.Credits.licenses,
            noticesHeader: Strings.Views.Settings.Credits.notices,
            translationsHeader: Strings.Views.Settings.Credits.translations,
            errorDescription: {
                ABI.AppError($0)
                    .localizedDescription
            }
        )
        .themeForm()
    }
}
