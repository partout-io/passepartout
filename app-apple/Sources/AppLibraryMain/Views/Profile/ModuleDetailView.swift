// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ModuleDetailView: View {

    @EnvironmentObject
    private var preferencesManager: PreferencesManager

    let profileEditor: ProfileEditor

    let moduleId: UUID?

    let moduleViewFactory: any ModuleViewFactory

    var body: some View {
        debugChanges()
        return Group {
            if let moduleId {
                editorView(forModuleWithId: moduleId)
            } else {
                emptyView
            }
        }
    }
}

private extension ModuleDetailView {

    @MainActor
    func editorView(forModuleWithId moduleId: UUID) -> some View {
        AnyView(moduleViewFactory.view(
            with: profileEditor,
            moduleId: moduleId
        ))
    }

    var emptyView: some View {
        Text(Strings.Global.Nouns.noSelection)
            .themeEmptyMessage()
    }
}

#Preview {
    ModuleDetailView(
        profileEditor: ProfileEditor(profile: .forPreviews),
        moduleId: Profile.forPreviews.modules.first?.id,
        moduleViewFactory: DefaultModuleViewFactory(registryObservable: .forPreviews)
    )
    .withMockEnvironment()
}
