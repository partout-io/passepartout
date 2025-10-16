// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
import Foundation
import XCTest

final class ModuleTypeTests: XCTestCase {
    func test_givenModuleType_whenModuleIsConnectionType_thenIsConnection() {
        XCTAssertTrue(ModuleType.openVPN.isConnection)
        XCTAssertTrue(ModuleType.wireGuard.isConnection)
    }
}
