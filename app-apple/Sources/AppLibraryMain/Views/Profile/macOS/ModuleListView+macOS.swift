// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import AppAccessibility
import CommonLibrary
import SwiftUI

struct ModuleListView: View, Routable {
    static let generalModuleId = UUID()

    @EnvironmentObject
    private var iapManager: IAPManager

    @Environment(\.appConfiguration)
    private var appConfiguration

    @Environment(\.isUITesting)
    private var isUITesting

    let profileEditor: ProfileEditor

    @Binding
    var selectedModuleId: UUID?

    @Binding
    var errorModuleIds: Set<UUID>

    @Binding
    var paywallReason: PaywallReason?

    let errorHandler: ErrorHandler

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
        .contextMenu {
            ModuleSendMenu(
                profileId: profileEditor.profile.id,
                module: module,
                errorHandler: errorHandler
            )
        }
    }

    @ViewBuilder
    func toolbarContent() -> some View {
        addModuleMenu
            .themeTip(.Profile.buildYourProfile)

        Button(action: removeSelectedModule) {
            ThemeImage(.remove)
        }
        .disabled(!canRemoveSelectedModule)

        EmptyView()
            .themeTip(Strings.Views.Profile.ModuleList.Section.footer, edge: .bottom)
    }

    var addModuleMenu: some View {
        AddModuleMenu(
            moduleTypes: availableTypes,
            withProviderType: appConfiguration.distributionTarget.supportsPaidFeatures
        ) {
            flow?.onNewModule($0)
        } label: {
            ThemeImage(.add)
        }
    }
}

private extension ModuleListView {
    var availableTypes: [ModuleType] {
        profileEditor.availableModuleTypes(forTarget: appConfiguration.distributionTarget)
    }

    var requiredGeneralFeatures: Set<ABI.AppFeature> {
        var features: Set<ABI.AppFeature> = []
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
        paywallReason: .constant(nil),
        errorHandler: .default()
    )
    .withMockEnvironment()
}

#endif
