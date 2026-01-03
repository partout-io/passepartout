// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import Foundation
import XCTest

@MainActor
struct ProviderServersScreen {
    let app: XCUIApplication

#if os(iOS)
    @discardableResult
    func discloseCountry(at index: Int) -> Self {
        let group = app.get(.ProviderServers.countryGroup, at: index)
        group.tap()
        return self
    }
#endif
}
