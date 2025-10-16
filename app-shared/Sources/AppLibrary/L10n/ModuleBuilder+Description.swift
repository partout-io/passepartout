// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension ModuleBuilder {

    @MainActor
    public func description(inEditor editor: ProfileEditor) -> String {
        moduleType.localizedDescription
    }
}
