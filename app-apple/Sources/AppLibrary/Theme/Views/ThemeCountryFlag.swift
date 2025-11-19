// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ThemeCountryFlag: View {
    private let code: String?

    private let placeholderTip: String?

    private let countryTip: ((String) -> String?)?

    public init(_ code: String?, placeholderTip: String? = nil, countryTip: ((String) -> String?)? = nil) {
        self.code = code
        self.placeholderTip = placeholderTip
        self.countryTip = countryTip
    }

    public var body: some View {
        if let code {
            text(withString: code.asCountryCodeEmoji, tip: countryTip?(code))
        } else {
            text(withString: "🌐", tip: placeholderTip)
        }
    }

    @ViewBuilder
    private func text(withString string: String, tip: String?) -> some View {
        if let tip {
            Text(verbatim: string)
                .help(tip)
        } else {
            Text(verbatim: string)
        }
    }
}
