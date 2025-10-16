// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileInfoButton: View {
    let preview: ProfilePreview

    let onEdit: (ProfilePreview) -> Void

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
