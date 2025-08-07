// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension OpenVPNModule.Builder: InteractiveViewProviding {
    public func interactiveView(with editor: ProfileEditor, onSubmit: @escaping () -> Void) -> some View {
        OpenVPNCredentialsGroup(
            draft: editor[self],
            isAuthenticating: true,
            onSubmit: onSubmit
        )
    }
}
