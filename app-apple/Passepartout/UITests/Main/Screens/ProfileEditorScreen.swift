// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import Foundation
import XCTest

@MainActor
struct ProfileEditorScreen {
    let app: XCUIApplication

    @discardableResult
    func enterModule(at index: Int) -> Self {
        let moduleLink = app.get(.Profile.moduleLink, at: index)
        moduleLink.tap()
        return self
    }

    @discardableResult
    func leaveModule() -> Self {
#if os(iOS)
        let backButton = app.navigationBars.element(boundBy: 1).buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 1.0))
        backButton.tap()
#endif
        return self
    }

    @discardableResult
    func editProviderServer() -> ProviderServersScreen {
        let providerServerLink = app.get(.Profile.providerServerLink)
        providerServerLink.tap()
        return ProviderServersScreen(app: app)
    }

    @discardableResult
    func closeProfile() -> AppScreen {
        let cancelButton = app.get(.Profile.cancel)
        cancelButton.tap()
        return AppScreen(app: app)
    }
}
