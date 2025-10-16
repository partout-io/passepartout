// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public protocol InteractiveViewProviding {
    associatedtype InteractiveContent: View

    @MainActor
    func interactiveView(with editor: ProfileEditor, onSubmit: @escaping () -> Void) -> InteractiveContent
}
