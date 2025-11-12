// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import CommonLibrary

import SwiftUI

struct ProfileSplitView: View, Routable {
    let profileManager: ProfileManager

    let profileEditor: ProfileEditor

    let moduleViewFactory: any ModuleViewFactory

    @Binding
    var paywallReason: PaywallReason?

    @ObservedObject
    var errorHandler: ErrorHandler

    var flow: ProfileCoordinator.Flow?

    @State
    private var detailPath = NavigationPath()

    @State
    private var selectedModuleId: UUID? = ModuleListView.generalModuleId

    @State
    private var errorModuleIds: Set<UUID> = []

    var body: some View {
        debugChanges()
        return NavigationSplitView {
            ModuleListView(
                profileEditor: profileEditor,
                selectedModuleId: $selectedModuleId,
                errorModuleIds: $errorModuleIds,
                paywallReason: $paywallReason,
                errorHandler: errorHandler,
                flow: flow
            )
            .navigationSplitViewColumnWidth(200)
        } detail: {
            Group {
                switch selectedModuleId {
                case ModuleListView.generalModuleId:
                    detailView(for: .general)
                        .navigationDestination(for: profileEditor, path: $detailPath)

                default:
                    detailView(for: .module(id: selectedModuleId))
                        .navigationDestination(for: profileEditor, path: $detailPath)
                }
            }
            .themeNavigationStack(path: $detailPath)
            .toolbar(content: toolbarContent)
            .environment(\.navigationPath, $detailPath)
        }
    }
}

// MARK: -

extension ProfileSplitView {

    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup {
            ProfileExportButton(editor: profileEditor)
            ProfileShareButton(editor: profileEditor)
            PurchaseRequiredView(
                requiring: [.sharing],
                reason: $paywallReason
            )
        }
        ToolbarItem(placement: .cancellationAction) {
            Button(Strings.Global.Actions.cancel, role: .cancel) {
                flow?.onCancelEditing()
            }
            .uiAccessibility(.Profile.cancel)
        }
        ToolbarItem(placement: .confirmationAction) {
            ProfileSaveButton(
                title: Strings.Global.Actions.save,
                errorModuleIds: $errorModuleIds
            ) {
                try await flow?.onSaveProfile()
            }
        }
    }
}

// MARK: - Destinations

extension ProfileSplitView {
    enum Detail: Hashable {
        case general

        case module(id: UUID?)
    }
}

private extension ProfileSplitView {

    @ViewBuilder
    func detailView(for detail: Detail) -> some View {
        switch detail {
        case .general:
            ProfileGeneralView(
                profileManager: profileManager,
                profileEditor: profileEditor,
                path: $detailPath,
                paywallReason: $paywallReason,
                flow: flow
            )

        case .module(let id):
            ModuleDetailView(
                profileEditor: profileEditor,
                moduleId: id,
                moduleViewFactory: moduleViewFactory
            )
        }
    }
}

#Preview {
    ProfileSplitView(
        profileManager: .forPreviews,
        profileEditor: ProfileEditor(profile: .newMockProfile()),
        moduleViewFactory: DefaultModuleViewFactory(registry: Registry()),
        paywallReason: .constant(nil),
        errorHandler: .default()
    )
    .withMockEnvironment()
}

#endif
