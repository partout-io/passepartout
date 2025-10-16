// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import CommonUtils
import SwiftUI

public struct ThemeTextList: View {
    private let title: String

    private let withEntries: Bool

    private let values: [String]

    private let copiable: Bool

    public init(_ title: String, withEntries: Bool = false, values: [String], copiable: Bool = false) {
        self.title = title
        self.withEntries = withEntries
        self.values = values
        self.copiable = copiable
    }

    public var body: some View {
        if !values.isEmpty {
            NavigationLink {
                Form {
                    ForEach(Array(values.enumerated()), id: \.offset) { pair in
                        HStack {
                            Text(pair.element)
                            if copiable {
                                Spacer()
                                Button {
                                    Utils.copyToPasteboard(pair.element)
                                } label: {
                                    ThemeImage(.copy)
                                }
                                // XXX: #584, necessary to avoid cell selection
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                .navigationTitle(title)
                .themeForm()
            } label: {
                ThemeRow(title, value: withEntries ? values.count.localizedEntries : nil)
            }
        } else {
            ThemeRow(title, value: Strings.Global.Nouns.empty)
        }
    }
}

#endif
