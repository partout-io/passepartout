// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS)

import CommonLibrary
import CommonUtils
import SwiftUI

struct ProfileEditView: View, Routable {

    @Environment(\.distributionTarget)
    private var distributionTarget

    let profileManager: ProfileManager

    @ObservedObject
    var profileEditor: ProfileEditor

    let moduleViewFactory: any ModuleViewFactory

    @Binding
    var path: NavigationPath

    @Binding
    var paywallReason: PaywallReason?

    var flow: ProfileCoordinator.Flow?

    @State
    private var errorModuleIds: Set<UUID> = []

    var body: some View {
        debugChanges()
        return List {
            ProfileNameSection(
                name: $profileEditor.profile.name
            )
            modulesSection
            profileEditor.shortcutsSections(path: $path)
            ProfileStorageSection(
                profileEditor: profileEditor,
                paywallReason: $paywallReason,
                flow: flow
            )
            ProfileBehaviorSection(profileEditor: profileEditor)
            ProfileActionsSection(
                profileManager: profileManager,
                profileEditor: profileEditor
            )
        }
        .toolbar(content: toolbarContent)
        .navigationTitle(Strings.Global.Nouns.profile)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: NavigationRoute.self, destination: pushDestination)
        .navigationDestination(for: profileEditor, path: $path)
    }
}

// MARK: -

private extension ProfileEditView {

    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            ProfileSaveButton(
                title: Strings.Global.Actions.save,
                errorModuleIds: $errorModuleIds
            ) {
                try await flow?.onCommitEditing()
            }
        }
        ToolbarItem(placement: .cancellationAction) {
            Button(Strings.Global.Actions.cancel, role: .cancel) {
                flow?.onCancelEditing()
            }
            .uiAccessibility(.Profile.cancel)
        }
    }

    var modulesSection: some View {
        Group {
            ForEach(profileEditor.modules, id: \.id, content: moduleRow)
                .onMove(perform: moveModules)
                .onDelete(perform: removeModules)

            addModuleMenu
        }
        .themeSection(
            header: Strings.Global.Nouns.modules,
            footer: Strings.Views.Profile.ModuleList.Section.footer
        )
        .themeTip(.Profile.buildYourProfile)
    }

    func moduleRow(for module: any ModuleBuilder) -> some View {
        EditorModuleToggle(profileEditor: profileEditor, module: module) {
            HStack {
                ThemeNavigatingButton(module.description(inEditor: profileEditor)) {
                    push(.moduleDetail(moduleId: module.id))
                }
                .uiAccessibility(.Profile.moduleLink)

                if errorModuleIds.contains(module.id) {
                    ThemeImage(.warning)
                } else if profileEditor.isActiveModule(withId: module.id) {
                    PurchaseRequiredView(
                        for: module as? AppFeatureRequiring,
                        reason: $paywallReason
                    )
                }
            }
        }
    }

    var addModuleMenu: some View {
        AddModuleMenu(
            moduleTypes: availableTypes,
            withProviderType: distributionTarget.supportsPaidFeatures
        ) {
            flow?.onNewModule($0)
        } label: {
            Text(Strings.Views.Profile.Rows.addModule)
        }
    }
}

private extension ProfileEditView {
    var availableTypes: [ModuleType] {
        profileEditor.availableModuleTypes(forTarget: distributionTarget)
    }

    func moveModules(from offsets: IndexSet, to newOffset: Int) {
        profileEditor.moveModules(from: offsets, to: newOffset)
    }

    func removeModules(at offsets: IndexSet) {
        profileEditor.removeModules(at: offsets)
    }
}

// MARK: - Destinations

private extension ProfileEditView {
    enum NavigationRoute: Hashable {
        case moduleDetail(moduleId: UUID)
    }

    @ViewBuilder
    func pushDestination(for item: NavigationRoute) -> some View {
        switch item {
        case .moduleDetail(let moduleId):
            ModuleDetailView(
                profileEditor: profileEditor,
                moduleId: moduleId,
                moduleViewFactory: moduleViewFactory
            )
            .environment(\.navigationPath, $path)
        }
    }

    func push(_ item: NavigationRoute) {
        path.append(item)
    }
}

#Preview {
    NavigationStack {
        ProfileEditView(
            profileManager: .forPreviews,
            profileEditor: ProfileEditor(profile: .newMockProfile()),
            moduleViewFactory: DefaultModuleViewFactory(registry: Registry()),
            path: .constant(NavigationPath()),
            paywallReason: .constant(nil)
        )
    }
    .withMockEnvironment()
}

#endif
