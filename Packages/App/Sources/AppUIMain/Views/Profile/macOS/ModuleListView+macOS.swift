//
//  ModuleListView+macOS.swift
//  Passepartout
//
//  Created by Davide De Rosa on 6/22/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

#if os(macOS)

import CommonLibrary
import CommonUtils
import PassepartoutKit
import SwiftUI
import UIAccessibility

struct ModuleListView: View, Routable {
    static let generalModuleId = UUID()

    @Environment(\.isUITesting)
    private var isUITesting

    @ObservedObject
    var profileEditor: ProfileEditor

    @Binding
    var selectedModuleId: UUID?

    @Binding
    var errorModuleIds: Set<UUID>

    @Binding
    var paywallReason: PaywallReason?

    var flow: ProfileCoordinator.Flow?

    var body: some View {
        List(selection: $selectedModuleId) {
            Section {
                NavigationLink(value: ProfileSplitView.Detail.general) {
                    HStack {
                        Text(Strings.Global.Nouns.general)
                        PurchaseRequiredView(
                            requiring: requiredGeneralFeatures,
                            reason: $paywallReason
                        )
                    }
                }
                .tag(Self.generalModuleId)
            }
            Group {
                ForEach(profileEditor.modules, id: \.id) { module in
                    NavigationLink(value: ProfileSplitView.Detail.module(id: module.id)) {
                        moduleRow(for: module)
                    }
                    .uiAccessibility(.Profile.moduleLink)
                }
                .onMove(perform: moveModules)
            }
            .themeSection(header: !profileEditor.modules.isEmpty ? Strings.Global.Nouns.modules : nil)
        }
        .onDeleteCommand(perform: removeSelectedModule)
        .toolbar(content: toolbarContent)
        .navigationTitle(profileEditor.profile.name)
    }
}

private extension ModuleListView {
    func moduleRow(for module: any ModuleBuilder) -> some View {
        HStack {
            Text(module.description(inEditor: profileEditor))
            if errorModuleIds.contains(module.id) {
                ThemeImage(.warning)
            } else if profileEditor.isActiveModule(withId: module.id) {
                PurchaseRequiredView(
                    for: module as? AppFeatureRequiring,
                    reason: $paywallReason
                )
            }
            Spacer()
            if !isUITesting {
                EditorModuleToggle(profileEditor: profileEditor, module: module) {
                    EmptyView()
                }
            }
        }
    }

    @ViewBuilder
    func toolbarContent() -> some View {
        addModuleMenu
        Button(action: removeSelectedModule) {
            ThemeImage(.remove)
        }
        .disabled(!canRemoveSelectedModule)
        EmptyView()
            .themeTip(Strings.Views.Profile.ModuleList.Section.footer, edge: .bottom)
    }

    var addModuleMenu: some View {
        AddModuleMenu(moduleTypes: profileEditor.availableModuleTypes) {
            flow?.onNewModule($0)
        } label: {
            ThemeImage(.add)
        }
    }
}

private extension ModuleListView {
    var requiredGeneralFeatures: Set<AppFeature> {
        var features: Set<AppFeature> = []
        if profileEditor.isShared {
            features.insert(.sharing)
        }
        return features
    }

    func moveModules(from offsets: IndexSet, to newOffset: Int) {
        profileEditor.moveModules(from: offsets, to: newOffset)
        // XXX: selection is lost after move, reset as a workaround
        selectedModuleId = nil
    }

    func removeModules(at offsets: IndexSet) {
        profileEditor.removeModules(at: offsets)
    }

    var effectiveSelectedModuleId: UUID? {
        guard selectedModuleId != Self.generalModuleId else {
            return nil
        }
        return selectedModuleId
    }

    var canRemoveSelectedModule: Bool {
        effectiveSelectedModuleId != nil
    }

    func removeSelectedModule() {
        guard let effectiveSelectedModuleId else {
            return
        }
        self.selectedModuleId = nil
        profileEditor.removeModule(withId: effectiveSelectedModuleId)
    }
}

#Preview {
    ModuleListView(
        profileEditor: ProfileEditor(profile: .forPreviews),
        selectedModuleId: .constant(nil),
        errorModuleIds: .constant([]),
        paywallReason: .constant(nil)
    )
    .withMockEnvironment()
}

#endif
