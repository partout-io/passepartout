// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct ModuleSendMenu: View {
    @Environment(ProfileObservable.self)
    private var profileObservable

    private let profileId: Profile.ID

    private let module: any ModuleBuilder

    private let errorHandler: ErrorHandler

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

    func sendModule(to preview: ABI.ProfilePreview?) {
        Task {
            do {
                var destination: Profile.Builder
                if let preview {
                    guard let existingDestination = profileObservable.profile(withId: preview.id) else {
                        throw PartoutError(.notFound)
                    }
                    destination = existingDestination.builder()
                } else {
                    destination = Profile.Builder()
                    destination.name = profileObservable.firstUniqueName(from: newProfileName)
                }
                var moduleCopy = module
                moduleCopy.id = UUID()
                let builtModule = try moduleCopy.build()

                destination.modules.append(builtModule)
                try await profileObservable.save(destination.build())
            } catch {
                pspLog(.profiles, .error, "Unable to copy module: \(error)")
                errorHandler.handle(error)
            }
        }
    }
}
