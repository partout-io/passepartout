// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public protocol ModuleDestinationProviding {
    associatedtype Destination: View

    func handlesRoute(_ route: AnyHashable) -> Bool

    @MainActor
    func moduleDestination(
        for route: AnyHashable,
        path: Binding<NavigationPath>,
        editor: ProfileEditor
    ) -> Destination
}
