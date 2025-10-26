// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils
import SwiftUI

public struct CreditsView: View {
    public init() {
    }

    public var body: some View {
        GenericCreditsView(
            credits: Self.credits,
            licensesHeader: Strings.Views.Settings.Credits.licenses,
            noticesHeader: Strings.Views.Settings.Credits.notices,
            translationsHeader: Strings.Views.Settings.Credits.translations,
            errorDescription: {
                AppError($0)
                    .localizedDescription
            }
        )
        .themeForm()
    }
}

private extension CreditsView {
    static let credits = Bundle.module.unsafeDecode(Credits.self, filename: "Credits")
}
