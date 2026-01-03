// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import Foundation
import XCTest

@MainActor
struct ProfileMenuScreen {
    let app: XCUIApplication

    @discardableResult
    func connectToProfile() -> ProviderServersScreen {
        let connectToButton = app.get(.App.ProfileMenu.connectTo)
        connectToButton.tap()
        return ProviderServersScreen(app: app)
    }

    @discardableResult
    func editProfile() -> ProfileEditorScreen {
        let editButton = app.get(.App.ProfileMenu.edit)
        editButton.tap()
        _ = app.get(.Profile.name)
        return ProfileEditorScreen(app: app)
    }
}
