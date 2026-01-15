// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public protocol ModuleShortcutsProviding: ModuleBuilder {
    associatedtype ShortcutsContent: View

    var isVisible: Bool { get }

    @MainActor
    func moduleShortcutsView(editor: ProfileEditor, path: Binding<NavigationPath>) -> ShortcutsContent
}
