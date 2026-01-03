// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import Foundation
import XCTest

@MainActor
final class MainScreenshotTests: XCTestCase, XCUIApplicationProviding {
    let app: XCUIApplication = {
        let app = XCUIApplication()
        app.appArguments = [.uiTesting]
        return app
    }()

    override func setUp() async throws {
        continueAfterFailure = false
        app.launch()
        app.activate()
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .portrait
        }
#endif
    }

    func testTakeScreenshots() async throws {
        let root = AppScreen(app: app)
            .waitForProfiles()
            .enableProfile(at: 1)

        let profile = root
            .editProfile(at: 2)

        await pause()
        try snapshot("03", "ProfileEditor", target: .sheet)

        profile
            .enterModule(at: 1)

        await pause()
        try snapshot("02", "OnDemand", target: .sheet)

        profile
            .leaveModule()
            .enterModule(at: 2)

        await pause()
        try snapshot("04", "DNS", target: .sheet)

        let app = profile
            .leaveModule()
            .closeProfile()

        await pause()
        try snapshot("01", "Connected")

        app
            .editProfile(at: 2)
            .editProviderServer()

        await pause()
        try snapshot("05", "ProviderServers", target: .sheet)

        print("Saved to: \(ScreenshotDestination.temporary.url)")
    }
}
