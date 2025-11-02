// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils
import SwiftUI

public struct ModuleCopyView: View {

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
        ProfileSelectorMenu(Strings.Views.Ui.ModuleCopy.title, excluding: profileId) {
            copyModule(to: $0)
        }
    }

    private func copyModule(to preview: ProfilePreview) {
        Task {
            do {
                guard let destination = profileManager.profile(withId: preview.id) else {
                    throw PartoutError(.notFound)
                }
                var builder = destination.builder()
                let builtModule = try module.build()
                builder.modules.append(builtModule)
                let newDestination = try builder.build()
                try await profileManager.save(newDestination)
            } catch {
                pp_log_g(.App.profiles, .error, "Unable to copy module to \(preview.id): \(error)")
                errorHandler.handle(error)
            }
        }
    }
}
