// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

@MainActor
public protocol ModuleDraftEditing {
    associatedtype Draft: ModuleBuilder

    var draft: ModuleDraft<Draft> { get }
}
