// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProviderConnectToButton<Label>: View where Label: View {
    @Environment(ProfileObservable.self)
    private var profileObservable

    let header: ABI.AppProfileHeader

    let onTap: (ABI.AppProfileHeader) -> Void

    let label: () -> Label

    var body: some View {
        profileObservable
            .profile(withId: header.id)?
            .activeProviderModule
            .map { _ in
                Button {
                    onTap(header)
                } label: {
                    label()
                }
            }
    }
}
