// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils
import SwiftUI

struct ProfileDuplicateButton<Label>: View where Label: View {
    let profileManager: ProfileManager

    let preview: ProfilePreview

    let errorHandler: ErrorHandler

    let label: () -> Label

    var body: some View {
        Button {
            Task {
                do {
                    try await profileManager.duplicate(profileWithId: preview.id)
                } catch {
                    errorHandler.handle(
                        error,
                        title: Strings.Global.Actions.duplicate,
                        message: Strings.Errors.App.duplicate(preview.name)
                    )
                }
            }
        } label: {
            label()
        }
    }
}
