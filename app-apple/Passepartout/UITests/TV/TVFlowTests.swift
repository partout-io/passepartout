// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import Foundation
import XCTest

@MainActor
final class TVFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.appArguments = [.uiTesting]
        app.launch()
    }

    func testShow() {
        AppScreen(app: app)
            .waitForProfiles()
    }

    func testPresentProfiles() {
        AppScreen(app: app)
            .waitForProfiles()
            .presentInitialProfiles()
    }

    func testConnect() {
        AppScreen(app: app)
            .waitForProfiles()
            .presentInitialProfiles()
            .enableProfile(up: 1)
    }

    func testReconnectToOtherProfile() {
        AppScreen(app: app)
            .waitForProfiles()
            .presentInitialProfiles()
            .enableProfile(up: 1)
            .presentProfilesWhileConnected()
            .enableProfile(up: 0)
    }
}
