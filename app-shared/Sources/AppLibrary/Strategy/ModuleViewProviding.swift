// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public protocol ModuleViewProviding {
    associatedtype Content: View

    @MainActor
    func moduleView(with parameters: ModuleViewParameters) -> Content
}

public struct ModuleViewParameters {
    public let registry: Registry

    public let editor: ProfileEditor

    public let impl: (any ModuleImplementation)?

    @MainActor
    public init(
        registry: Registry,
        editor: ProfileEditor,
        impl: (any ModuleImplementation)?
    ) {
        self.registry = registry
        self.editor = editor
        self.impl = impl
    }
}
