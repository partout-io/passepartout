// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProviderConnectToButton<Label>: View where Label: View {
    let profile: Profile

    let onTap: (Profile) -> Void

    let label: () -> Label

    var body: some View {
        profile
            .activeProviderModule
            .map { _ in
                Button {
                    onTap(profile)
                } label: {
                    label()
                }
            }
    }
}
