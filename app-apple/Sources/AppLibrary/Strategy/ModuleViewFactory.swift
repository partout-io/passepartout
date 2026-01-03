// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public protocol ModuleViewFactory: AnyObject {
    associatedtype Content: View

    @MainActor
    func view(with editor: ProfileEditor, moduleId: UUID) -> Content
}
