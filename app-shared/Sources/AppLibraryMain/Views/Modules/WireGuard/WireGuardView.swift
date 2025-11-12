// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

import SwiftUI

struct WireGuardView: View, ModuleDraftEditing {

    @Environment(\.navigationPath)
    private var path

    @ObservedObject
    var draft: ModuleDraft<WireGuardModule.Builder>

    let impl: WireGuardModule.Implementation?

    @State
    private var paywallReason: PaywallReason?

    @State
    private var configurationViewModel = ConfigurationView.ViewModel()

    @State
    private var isImporting = false

    @StateObject
    private var errorHandler: ErrorHandler = .default()

    init(draft: ModuleDraft<WireGuardModule.Builder>, parameters: ModuleViewParameters) {
        self.draft = draft
        impl = parameters.impl as? WireGuardModule.Implementation
    }

    var body: some View {
        contentView
            .moduleView(draft: draft)
            .modifier(ImportModifier(
                draft: draft,
                impl: impl,
                isImporting: $isImporting,
                errorHandler: errorHandler,
                onImport: {
                    guard let configurationBuilder = $0 else {
                        return
                    }
                    configurationViewModel.load(from: configurationBuilder)
                }
            ))
            .modifier(ModuleDynamicPaywallModifier(reason: $paywallReason))
            .withErrorHandler(errorHandler)
    }
}

// MARK: - Content

private extension WireGuardView {

    @ViewBuilder
    var contentView: some View {
        if draft.module.configurationBuilder != nil {
            ModuleImportSection(isImporting: $isImporting)
            ConfigurationView(
                draft: draft,
                viewModel: $configurationViewModel,
                keyGenerator: impl?.keyGenerator
            )
            .onLoad {
                guard let configurationBuilder = draft.module.configurationBuilder else {
                    return
                }
                configurationViewModel.load(from: configurationBuilder)
            }
        } else {
            ModuleImportSection(isImporting: $isImporting)
        }
    }
}

private extension WireGuardView {
    func editConfiguration() {
        // TODO: #397, edit configuration as text
    }
}

// MARK: - Previews

#Preview {
    let module = WireGuardModule.Builder(configurationBuilder: .forPreviews)
    return module.preview()
}
