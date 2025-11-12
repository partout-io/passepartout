// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

import SwiftUI

public struct ModuleSendMenu: View {

    @EnvironmentObject
    private var profileManager: ProfileManager

    private let profileId: Profile.ID

    private let module: any ModuleBuilder

    @ObservedObject
    private var errorHandler: ErrorHandler

    public init(profileId: Profile.ID, module: any ModuleBuilder, errorHandler: ErrorHandler) {
        self.profileId = profileId
        self.module = module
        self.errorHandler = errorHandler
    }

    public var body: some View {
        ProfileSelectorMenu(
            Strings.Views.Ui.ModuleSend.title,
            withNewTitle: newProfileName,
            excluding: profileId,
            onSelect: sendModule(to:)
        )
    }
}

private extension ModuleSendMenu {
    var newProfileName: String {
        Strings.Views.Ui.ModuleSend.newProfileName(module.moduleType)
    }

    func sendModule(to preview: ProfilePreview?) {
        Task {
            do {
                var destination: Profile.Builder
                if let preview {
                    guard let existingDestination = profileManager.profile(withId: preview.id) else {
                        throw PartoutError(.notFound)
                    }
                    destination = existingDestination.builder()
                } else {
                    destination = Profile.Builder()
                    destination.name = profileManager.firstUniqueName(from: newProfileName)
                }
                var moduleCopy = module
                moduleCopy.id = UUID()
                let builtModule = try moduleCopy.build()

                destination.modules.append(builtModule)
                try await profileManager.save(destination.build())
            } catch {
                pp_log_g(.App.profiles, .error, "Unable to copy module: \(error)")
                errorHandler.handle(error)
            }
        }
    }
}
