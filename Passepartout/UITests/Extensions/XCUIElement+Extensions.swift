//
//  XCUIElement+Extensions.swift
//  Passepartout
//
//  Created by Davide De Rosa on 11/28/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import UIAccessibility
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
