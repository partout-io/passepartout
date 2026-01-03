// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import Foundation
import XCTest

@MainActor
final class TVScreenshotTests: XCTestCase, XCUIApplicationProviding {
    let app: XCUIApplication = {
        let app = XCUIApplication()
        app.appArguments = [.uiTesting]
        return app
    }()

    override func setUp() async throws {
        continueAfterFailure = false
        app.launch()
    }

    func testTakeScreenshots() async throws {
        let root = AppScreen(app: app)
            .waitForProfiles()
            .presentInitialProfiles()
            .enableProfile(up: 1)

        await pause()
        try snapshot("01", "Connected")

        root
            .presentProfilesWhileConnected()

        await pause()
        try snapshot("02", "ConnectedWithProfileList")

        root
            .enableProfile(up: 0)

        await pause()
        try snapshot("03", "OnDemand")

        print("Saved to: \(ScreenshotDestination.temporary.url)")
    }
}
