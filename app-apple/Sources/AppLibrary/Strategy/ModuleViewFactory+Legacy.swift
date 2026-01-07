// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout
import SwiftUI

public final class LegacyModuleViewFactory: ModuleViewFactory {
    private let registry: Registry

    public init(registry: Registry) {
        self.registry = registry
    }

    @ViewBuilder
    public func view(with editor: ProfileEditor, moduleId: UUID) -> some View {
        let result = editor.moduleViewProvider(withId: moduleId, registry: registry)
        if let result {
            AnyView(result.provider.moduleView(with: .init(
                registry: registry,
                editor: editor,
                impl: result.impl
            )))
            .navigationTitle(result.title)
        }
    }
}

private extension ProfileEditor {
    func moduleViewProvider(withId moduleId: UUID, registry: Registry) -> ModuleViewProviderResult? {
        guard let module = module(withId: moduleId) else {
//            assertionFailure("No module with ID \(moduleId)")
            return nil
        }
        guard let provider = module as? any LegacyModuleViewProviding else {
            assertionFailure("\(type(of: module)) does not provide a default view")
            return nil
        }
        return ModuleViewProviderResult(
            title: module.moduleType.localizedDescription,
            provider: provider,
            impl: registry.implementation(for: module)
        )
    }
}

private struct ModuleViewProviderResult {
    let title: String

    let provider: any LegacyModuleViewProviding

    let impl: ModuleImplementation?
}
