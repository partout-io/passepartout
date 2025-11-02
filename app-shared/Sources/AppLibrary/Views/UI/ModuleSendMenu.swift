// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils
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
        ProfileSelectorMenu(Strings.Views.Ui.ModuleCopy.title, excluding: profileId) {
            sendModule(to: $0)
        }
    }

    private func sendModule(to preview: ProfilePreview) {
        Task {
            do {
                guard let destination = profileManager.profile(withId: preview.id) else {
                    throw PartoutError(.notFound)
                }
                var moduleCopy = module
                moduleCopy.id = UUID()
                let builtModule = try moduleCopy.build()

                var builder = destination.builder()
                builder.modules.append(builtModule)
                try await profileManager.save(builder.build())
            } catch {
                pp_log_g(.App.profiles, .error, "Unable to copy module to \(preview.id): \(error)")
                errorHandler.handle(error)
            }
        }
    }
}
