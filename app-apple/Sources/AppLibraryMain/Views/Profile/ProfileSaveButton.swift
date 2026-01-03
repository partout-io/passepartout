// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileSaveButton: View {
    let title: String

    @Binding
    var errorModuleIds: Set<UUID>

    let action: () async throws -> Void

    var body: some View {
        Button(title) {
            Task {
                do {
                    try await action()
                    errorModuleIds = []
                } catch {
                    switch ABI.AppError(error) {
                    case .partout(let ppError):
                        switch ppError.code {
                        case .incompatibleModules:
                            guard let modules = ppError.userInfo as? [Module] else {
                                errorModuleIds = []
                                return
                            }
                            errorModuleIds = Set(modules.map(\.id))

                        default:
                            errorModuleIds = []
                        }

                    case .malformedModule(let module, _):
                        errorModuleIds = [module.id]

                    default:
                        errorModuleIds = []
                    }
                }
            }
        }
    }
}
