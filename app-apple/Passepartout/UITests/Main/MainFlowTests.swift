// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import Foundation
import XCTest

@MainActor
final class MainFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.appArguments = [.uiTesting]
        app.launch()
        app.activate()
    }

    func testConnect() {
        AppScreen(app: app)
            .waitForProfiles()
            .enableProfile(at: 2)
    }

    func testEditProfile() {
        AppScreen(app: app)
            .waitForProfiles()
            .editProfile(at: 2)
    }

    func testEditProfileModule() {
        AppScreen(app: app)
            .waitForProfiles()
            .editProfile(at: 2)
            .enterModule(at: 1)
            .leaveModule()
    }

#if os(iOS)
    func testDiscloseProviderCountry() {
        AppScreen(app: app)
            .waitForProfiles()
            .editProfile(at: 2)
            .editProviderServer()
    }
#endif
}
