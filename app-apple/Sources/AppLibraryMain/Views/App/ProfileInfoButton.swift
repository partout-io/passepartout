// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileInfoButton: View {
    let preview: ABI.ProfilePreview

    let onEdit: (ABI.ProfilePreview) -> Void

    var body: some View {
        Button {
            onEdit(preview)
        } label: {
            ThemeImage(.info)
        }
        // XXX: #584, necessary to avoid cell selection
        .buttonStyle(.borderless)
    }
}
