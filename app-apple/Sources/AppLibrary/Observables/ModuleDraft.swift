// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

// FIXME: #1594, Bound to objectWillChange.send()
@MainActor
public final class ModuleDraft<T>: ObservableObject where T: ModuleBuilder {
    private weak var editor: ProfileEditor?

    private let staticEditor: ProfileEditor?

    private let moduleId: UUID

    public var module: T {
        get {
            guard let editor else {
                fatalError("Editor is nil")
            }
            guard let foundModule = editor.module(withId: moduleId) else {
//                fatalError("Module not found in editor: \(moduleId)")
                return T.empty()
            }
            guard let matchingModule = foundModule as? T else {
                fatalError("Type mismatch when binding to editor module: \(type(of: foundModule)) != \(T.self)")
            }
            return matchingModule
        }
        set {
            objectWillChange.send()
            editor?.saveModule(newValue, activating: false)
        }
    }

    public init(module: T) {
        staticEditor = ProfileEditor(modules: [module])
        editor = staticEditor
        moduleId = module.id
    }

    init(editor: ProfileEditor, module: T) {
        self.editor = editor
        staticEditor = nil
        moduleId = module.id
    }
}
