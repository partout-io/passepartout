// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

extension EnvironmentValues {
    var navigationPath: Binding<NavigationPath> {
        get {
            self[NavigationPathKey.self]
        }
        set {
            self[NavigationPathKey.self] = newValue
        }
    }

    var dismissProfile: () -> Void {
        get {
            self[DismissProfileKey.self]
        }
        set {
            self[DismissProfileKey.self] = newValue
        }
    }
}

private struct NavigationPathKey: EnvironmentKey {
    static var defaultValue: Binding<NavigationPath> {
        .constant(NavigationPath())
    }
}

private struct DismissProfileKey: EnvironmentKey {
    static var defaultValue: () -> Void {{}}
}
