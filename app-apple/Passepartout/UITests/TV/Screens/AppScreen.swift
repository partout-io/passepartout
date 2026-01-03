// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import Foundation
import XCTest

@MainActor
struct AppScreen {
    let app: XCUIApplication

    private let remote: XCUIRemote = .shared

    @discardableResult
    func waitForProfiles() -> Self {
        app.get(.App.profilesHeader)
        return self
    }

    @discardableResult
    func presentInitialProfiles() -> Self {
        remote.press(.down)
        return self
    }

    @discardableResult
    func enableProfile(up: Int) -> Self {
        let profileButton = app.get(.App.ProfileList.profile)
        remote.press(.right)
        for _ in 0..<up {
            remote.press(.up)
        }
        remote.press(.select)
        profileButton.waitForNonExistence(timeout: 1.0)
        return self
    }

    @discardableResult
    func presentProfilesWhileConnected() -> Self {
        remote.press(.down)
        _ = app.get(.App.ProfileList.profile)
        return self
    }
}
