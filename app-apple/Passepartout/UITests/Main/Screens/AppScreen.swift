// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import Foundation
import XCTest

@MainActor
struct AppScreen {
    let app: XCUIApplication

    @discardableResult
    func waitForProfiles() -> Self {
        app.get(.App.profilesHeader)
        return self
    }

    @discardableResult
    func enableProfile(at index: Int) -> Self {
        let profileToggle = app.get(.App.profileToggle, at: index)
        profileToggle.tap()
        return self
    }

    @discardableResult
    func editProfile(at index: Int) -> ProfileEditorScreen {
        let profileMenu = app.get(.App.profileEdit, at: index)
        profileMenu.tap()
        return ProfileEditorScreen(app: app)
    }
}
