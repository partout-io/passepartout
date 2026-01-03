// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct EditorModuleToggle<Label>: View where Label: View {
    let profileEditor: ProfileEditor

    let module: any ModuleBuilder

    let label: () -> Label

    var body: some View {
        Toggle(isOn: isActiveBinding, label: label)
    }
}

private extension EditorModuleToggle {
    var isActiveBinding: Binding<Bool> {
        Binding {
            profileEditor.isActiveModule(withId: module.id)
        } set: { _ in
            profileEditor.toggleModule(withId: module.id)
        }
    }
}
