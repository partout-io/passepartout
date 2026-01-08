// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout
import SwiftUI

public protocol ModuleViewProviding {
    associatedtype Content: View

    @MainActor
    func moduleView(with editor: ProfileEditor) -> Content
}
