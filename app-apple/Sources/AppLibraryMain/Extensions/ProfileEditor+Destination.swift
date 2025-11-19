// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension View {
    public func navigationDestination(for editor: ProfileEditor, path: Binding<NavigationPath>) -> some View {
        navigationDestination(for: ProfileRoute.self) { route in
            editor.destinationHandler(for: route.wrapped)
                .map { handler in
                    AnyView(handler.moduleDestination(
                        for: route.wrapped,
                        path: path,
                        editor: editor
                    ))
                }
        }
    }
}

private extension ProfileEditor {
    func destinationHandler(for route: AnyHashable) -> (any ModuleBuilder & ModuleDestinationProviding)? {
        modules.first {
            guard let handler = $0 as? any ModuleDestinationProviding else {
                return false
            }
            return handler.handlesRoute(route)
        } as? any ModuleBuilder & ModuleDestinationProviding
    }
}
