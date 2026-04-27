// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileDuplicateButton<Label>: View where Label: View {
    let profileObservable: ProfileObservable

    let header: ABI.AppProfileHeader

    let errorHandler: ErrorHandler

    let label: () -> Label

    var body: some View {
        Button {
            Task {
                do {
                    try await profileObservable.duplicate(profileWithId: header.id)
                } catch {
                    errorHandler.handle(
                        error,
                        title: Strings.Global.Actions.duplicate,
                        message: Strings.Errors.App.duplicate(header.name)
                    )
                }
            }
        } label: {
            label()
        }
    }
}
