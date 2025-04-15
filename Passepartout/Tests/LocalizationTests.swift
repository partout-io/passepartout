//
//  LocalizationTests.swift
//  Passepartout
//
//  Created by Davide De Rosa on 11/25/24.
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
@testable import PartoutWireGuardGo
import UILibrary
import WireGuardKit
import XCTest

final class LocalizationTests: XCTestCase {
    func test_givenModules_whenTranslateApp_thenWorks() {
        XCTAssertEqual(Strings.Global.Actions.connect, "Connect")
        XCTAssertEqual(Strings.Global.Nouns.address, "Address")
    }

    func test_givenModules_whenTranslateWireGuard_thenWorks() {
        let sut = TunnelConfiguration.ParseError.noInterface
        XCTAssertEqual(sut.localizedDescription, "Configuration must have an ‘Interface’ section.")
    }
}
