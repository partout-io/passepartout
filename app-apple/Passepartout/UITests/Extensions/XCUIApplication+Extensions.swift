// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import Foundation
import XCTest

protocol XCUIApplicationProviding {
    var app: XCUIApplication { get }
}

extension XCUIApplication {
    var appArguments: [AppCommandLine.Value] {
        get {
            launchArguments.compactMap(AppCommandLine.Value.init(rawValue:))
        }
        set {
            launchArguments = newValue.map(\.rawValue)
        }
    }
}
