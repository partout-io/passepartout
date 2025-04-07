//
//  ProfileSaveButton.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/6/24.
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

import CommonLibrary
import Partout
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
                    switch AppError(error) {
                    case .generic(let ppError):
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
