// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout
import SwiftUI

public final class DefaultModuleViewFactory: ModuleViewFactory {
    private let registryObservable: RegistryObservable

    public init(registryObservable: RegistryObservable) {
        self.registryObservable = registryObservable
    }

    @ViewBuilder
    public func view(with editor: ProfileEditor, moduleId: UUID) -> some View {
        let result = editor.moduleViewProvider(withId: moduleId, registryObservable: registryObservable)
        if let result {
            AnyView(result.provider.moduleView(with: editor))
                .navigationTitle(result.title)
        }
    }
}

private extension ProfileEditor {
    func moduleViewProvider(withId moduleId: UUID, registryObservable: RegistryObservable) -> ModuleViewProviderResult? {
        guard let module = module(withId: moduleId) else {
//            assertionFailure("No module with ID \(moduleId)")
            return nil
        }
        guard let provider = module as? any ModuleViewProviding else {
            assertionFailure("\(type(of: module)) does not provide a default view")
            return nil
        }
        return ModuleViewProviderResult(
            title: module.moduleType.localizedDescription,
            provider: provider,
        )
    }
}

private struct ModuleViewProviderResult {
    let title: String

    let provider: any ModuleViewProviding
}
