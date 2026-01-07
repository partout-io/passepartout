// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout
import SwiftUI

public protocol LegacyModuleViewProviding {
    associatedtype Content: View

    @MainActor
    func moduleView(with parameters: LegacyModuleViewParameters) -> Content
}

public struct LegacyModuleViewParameters {
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
