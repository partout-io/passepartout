// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileInfoButton: View {
    let header: ABI.AppProfileHeader

    let onEdit: (ABI.AppProfileHeader) -> Void

    var body: some View {
        Button {
            onEdit(header)
        } label: {
            ThemeImage(.info)
        }
        // XXX: #584, Necessary to avoid cell selection
        .buttonStyle(.borderless)
    }
}
