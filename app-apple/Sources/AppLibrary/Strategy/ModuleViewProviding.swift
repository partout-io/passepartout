// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout
import SwiftUI

public protocol ModuleViewProviding {
    associatedtype Content: View

    @MainActor
    func moduleView(with parameters: ModuleViewParameters) -> Content
}

public struct ModuleViewParameters {
    public let registryObservable: RegistryObservable

    public let editor: ProfileEditor

    public let impl: (any ModuleImplementation)?

    @MainActor
    public init(
        registryObservable: RegistryObservable,
        editor: ProfileEditor,
        impl: (any ModuleImplementation)?
    ) {
        self.registryObservable = registryObservable
        self.editor = editor
        self.impl = impl
    }
}
