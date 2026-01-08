// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

final class DefaultModuleViewFactory: ModuleViewFactory {
    init() {
    }

    @ViewBuilder
    func view(with editor: ProfileEditor, moduleId: UUID) -> some View {
        let result = editor.moduleViewProvider(withId: moduleId)
        if let result {
            AnyView(result.provider.moduleView(with: editor))
                .navigationTitle(result.title)
        }
    }
}

private extension ProfileEditor {
    func moduleViewProvider(withId moduleId: UUID) -> ModuleViewProviderResult? {
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
            provider: provider
        )
    }
}

private struct ModuleViewProviderResult {
    let title: String

    let provider: any ModuleViewProviding
}
