// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import SwiftUI
import XCTest

extension XCTestCase {
    enum ScreenshotDestination {
        case attachment

        case temporary
    }

    enum ScreenshotTarget {
        case sheet

        case window
    }
}

extension XCTestCase.ScreenshotDestination {
    var url: URL {
        switch self {
        case .attachment:
            fatalError("Can this be found?")
        case .temporary:
            return URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }
}

@MainActor
extension XCUIApplicationProviding where Self: XCTestCase {
    func pause() async {
        try? await Task.sleep(for: .seconds(2))
    }

    func snapshot(
        _ index: String,
        _ title: String,
        destination: ScreenshotDestination = .attachment,
        target: ScreenshotTarget = .window
    ) throws {
        let container = container(for: target)
        let screenshot = container.screenshot()

        switch destination {
        case .attachment:
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = index
            attachment.lifetime = .keepAlways
            add(attachment)

        case .temporary:
            let filename = deviceFilename(for: index)
            let url = URL(fileURLWithPath: filename, relativeTo: destination.url)
            try screenshot.pngRepresentation.write(to: url)
        }
    }

    private func deviceFilename(for index: String) -> String {
#if os(iOS)
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
#elseif os(macOS)
        let device = "mac"
#elseif os(tvOS)
        let device = "appletv"
#endif
        return "\(device)_\(index).png"
    }

    private func container(for target: ScreenshotTarget) -> XCUIElement {
#if os(iOS) || os(tvOS)
        app.windows.firstMatch
#else
        switch target {
        case .sheet:
            return app.sheets.firstMatch
        case .window:
            return app.windows.firstMatch
        }
#endif
    }
}
