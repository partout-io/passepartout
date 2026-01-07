// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary
import SwiftUI

struct ModuleViewModifier<T>: ViewModifier where T: ModuleBuilder & Equatable {

    @Environment(\.isUITesting)
    private var isUITesting

    @ObservedObject
    var draft: ModuleDraft<T>

    let withUUID: Bool

    func body(content: Content) -> some View {
        Form {
            content
#if DEBUG
            if !isUITesting && withUUID {
                Section {
                    UUIDText(uuid: draft.module.id)
                }
            }
#endif
        }
        .themeForm()
        .themeAnimation(on: draft.module, category: .modules)
    }
}

extension View {
    func moduleView<T>(draft: ModuleDraft<T>, withUUID: Bool = true) -> some View where T: ModuleBuilder & Equatable {
        modifier(ModuleViewModifier(draft: draft, withUUID: withUUID))
    }
}
