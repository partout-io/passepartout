// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import Foundation
import XCTest

extension XCUIElement {

    @discardableResult
    func get(_ info: AccessibilityInfo, at index: Int = 0, timeout: TimeInterval = 1.0) -> XCUIElement {
        let element = query(for: info.elementType)
            .matching(identifier: info.id)
            .element(boundBy: index)

        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        return element
    }
}

private extension XCUIElement {
    func query(for elementType: AccessibilityInfo.ElementType) -> XCUIElementQuery {
#if os(iOS) || os(tvOS)
        switch elementType {
        case .button, .link, .menu, .menuItem:
            return buttons
        case .text:
            return staticTexts
        case .toggle:
            return switches
        }
#else
        switch elementType {
        case .button, .link:
            return buttons
        case .menu:
            return menuButtons
        case .menuItem:
            return menuItems
        case .text:
            return staticTexts
        case .toggle:
            return checkBoxes
        }
#endif
    }
}
